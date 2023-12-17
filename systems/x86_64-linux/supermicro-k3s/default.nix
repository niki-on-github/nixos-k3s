{ config, lib, pkgs, inputs, ... }:
let
  user = "nix";
  cpu = "intel";
  domain = "server02";
  ip = "10.0.1.200";
  gateway = "10.0.1.1";
in
{
  imports = with inputs.self.nixosModules; [
    inputs.self.nixosRoles.k3s
    inputs.home-manager.nixosModules.home-manager
  ];

  hardware.cpu."${cpu}".updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  security.pki.certificateFiles = [
    ./secrets/ca-cert.crt
  ];  
  
  age.secrets = {
    flux-git-auth.file = ./secrets/flux-git-auth.yaml.age;
    flux-sops-age.file = ./secrets/flux-sops-age.yaml.age;
    minio-credentials = {
      file = ./secrets/minio-credentials.age;
      mode = "770";
      owner = "minio";
      group = "minio";
    };
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.sops.yaml;
    secrets.user-password.neededForUsers = true;
  };
  
  templates = {
    system = {
      setup = {
        enable = true;
        encrypt = true;
        disk = "/dev/disk/by-id/ata-SanDisk_SDSSDH3_512G_191805802811";
      };
    };
    services = {
      k3s = {
        enable = true;
        flux.enable = true;
        minio = {
          enable = true;
          credentialsFile = config.age.secrets.minio-credentials.path;
          buckets = ["volsync" "postgres"];
        };
      };
      docker = {
        enable = true;
        gatewayIp = "${gateway}";
      };
    };
  };

  services.gitea = {
    enable = true;
    settings = {
      server = {
        HTTP_PORT = 3000;
        ROOT_URL = "http://${domain}:3000/";
        DOMAIN = "${domain}";
        SSH_DOMAIN = "${domain}";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      ser2net
    ];
  };

  # open ports for gitea, selfhosted unify-network-application and Ser2Net Zigbee adapter
  networking.firewall.allowedTCPPorts = [22 3000 3478 10001 20108];

  users = {
    groups = {
      data = { 
        name = "data"; 
        members = ["git" "${user}"]; 
        gid = 1000;
      };
    };
    users = {
      ${user} = {
        isNormalUser = true;
        description = "nix user";
        createHome = true;
        # use `mkpasswd -m sha-512 | tr -d '\n'` to get the password hash for your sops file
        hashedPasswordFile = config.sops.secrets.user-password.path;
        home = "/home/${user}";
        extraGroups = [
          "audit"
          "dialout"
          "users"
          "sshusers"
          "storage"
          "wheel"
        ];
        #TODO declarative way to add this to gitea webui ssh keys?
        openssh.authorizedKeys.keyFiles = [
          ./secrets/ssh.server02.lan.pub
        ];
      };
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      ${user} = import ./home.nix;
    };
  };
  
  systemd.tmpfiles.rules = [
    "d /opt/k3s 0775 ${user} data -"
    "d /opt/k3s/data 0775 ${user} data -"
    "d /mnt/backup 0775 ${user} data -"
    "d /mnt/backup/k3s 0775 ${user} data -"
    "d /mnt/backup/k3s/minio 0775 ${user} data -"
    "d /home/${user}/.kube 0775 ${user} data -"
    "d /var/lib/rancher/k3s/server/manifests 0775 root data -"
    "L /home/${user}/.kube/config  - - - - /etc/rancher/k3s/k3s.yaml"
    "L /var/lib/rancher/k3s/server/manifests/flux.yaml - - - - /etc/flux.yaml"
    "L /var/lib/rancher/k3s/server/manifests/flux-git-auth.yaml - - - - ${config.age.secrets.flux-git-auth.path}"
    "L /var/lib/rancher/k3s/server/manifests/flux-sops-age.yaml - - - - ${config.age.secrets.flux-sops-age.path}"                                  
  ];
  
  # required for deploy-rs
  nix.settings.trusted-users = [ "root" "${user}" ];

  # git url schmeas: 
  # - 'git@server02.lan:r/gitops-homelab.git'
  # - 'ssh://git@server02.lan/home/git/r/gitops-homelab.git'
  # - 'ssh://git@server02.lan/~/r/gitops-homelab.git' => ~ is not supported in flux git repo url!
  # flux git secret:
  # 1. flux create secret git flux-git-auth --url="ssh://git@${domain}/~/r/gitops-homelab.git" --private-key-file={{ .PRIVATE_SSH_KEYFILE }} --export > flux-git-secret.yaml
  # 2. manually change the knwon_hosts to `ssh-keyscan ${domain}` ssh-ed25519 output
  # 3. encrypt yaml with age
  environment.etc."flux.yaml" = {
    mode = "0750";
    text = ''
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      metadata:
        name: flux-system
        namespace: flux-system
      spec:
        interval: 2m
        ref:
          branch: main
        secretRef:
          name: flux-git-auth
        url: ssh://gitea@${domain}.lan/r/nixos-k3s.git
      ---
      apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: flux-system
        namespace: flux-system
      spec:
        interval: 2m
        path: ./kubernetes/flux
        prune: true
        wait: false
        sourceRef:
          kind: GitRepository
          name: flux-system
        decryption:
          provider: sops
          secretRef:
            name: sops-age
    '';
  };

  # Config for ConBee II
  environment.etc."ser2net.yaml" = {
    mode = "0755";
    text = ''
      connection: &con01
        accepter: tcp,20108
        connector: serialdev,/dev/ttyACM0,115200n81,nobreak,local
        options:
          kickolduser: true
    '';
  };

  systemd.services.ser2net = {
    wantedBy = [ "multi-user.target" ];
    description = "Serial to network proxy";
    after = [ "network.target" "dev-ttyACM0.device" ];
    serviceConfig = {
        Type = "simple";
        User = "root"; # todo user with only dialout group?
        ExecStart = ''${pkgs.ser2net}/bin/ser2net -n -c /etc/ser2net.yaml''; 
        ExecReload = ''kill -HUP $MAINPID'';
        Restart = "on-failure";
      };
  };
}
