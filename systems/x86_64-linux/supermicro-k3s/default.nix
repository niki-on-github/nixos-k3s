{ config, lib, pkgs, nixpkgs-unstable, inputs, ... }:
let
  user = "nix";
  cpu = "intel";
  domain = "server02.lan";
  ip = "10.0.1.11";
  dns = "10.0.1.1";
  subnet = 24;
  gateway = "10.0.1.1";
  interface = "eno3";
  cpufreqmax = 2100000; 
  bridge = "br1";
  disk = "/dev/disk/by-id/nvme-Lexar_SSD_NM790_4TB_NJF381R007355PXXXX";
in
{
  imports = with inputs.self.nixosModules; [
    inputs.self.nixosRoles.k3s
    inputs.home-manager.nixosModules.home-manager
  ];

  hardware.cpu."${cpu}".updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking.firewall = {
    enable = true;
    # NOTE: `loose` required for cilium when using without kube-proxy replacement to get working livenes probe for pods. With this settings the cluster is mostly usable with exception of
    # Cilium DNS Filtering: msg="Timeout waiting for response to forwarded proxied DNS lookup" dnsName=vpn-gateway-pod-gateway.vpn-gateway.svc.cluster.local. error="read udp 10.42.0.183:43844->10.42.0.176:53: i/o timeout" ipAddr="10.42.0.183:43844" subsys=fqdn/dnsproxy 
    # => Therefore we have to use `checkReversePath=false` to get our vpn-gateway CiliumNetworkPolicy with DNS Filter working (when installing without cilium kube-proxy replacement).
    checkReversePath = false;     
    allowedTCPPorts = [
      3000 # nixos gitea
      8080 # unifi control
      18089 # monerod rpc
      20108 # zigbee adapter via serial2net
      22000 # syncthing local discovery
    ];
    allowedUDPPorts = [
      3478 # unifi stun
      10001 # unifi discovery
      21027 # syncthing discovery broadcast
      51820 # wg-easy
    ];
  };

  services.k3s.package = pkgs.k3s; 
  systemd.services.k3s.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 60";
  
  age.secrets = {
    flux-git-auth.file = ./secrets/flux-git-auth.yaml.age;
    flux-sops-age.file = ./secrets/flux-sops-age.yaml.age;
    minio-credentials = {
      file = ./secrets/minio-credentials.age;
      mode = "770";
      owner = "minio";
      group = "minio";
    };
    "sops-age-keys.txt" = {
        file = ./secrets/sops-age-keys.txt.age;
        path = "/home/${user}/.config/sops/age/keys.txt";
        owner = "${user}";
        group = "users";
        mode = "600";
      };
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.sops.yaml;
    secrets.user-password.neededForUsers = true;
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking = {
    defaultGateway = "${gateway}";
    nameservers = [ "${dns}" ];
    bridges = {
      "${bridge}" = {
        interfaces = [ "${interface}" ];
      };
    };
    interfaces."${bridge}".ipv4.addresses = [ 
      { address = "${ip}"; prefixLength = subnet; }
    ];
  };

  templates = {
    apps = {
      modernUnix.enable = true;
      monitoring.enable = true;
    };
    system = {
      setup = {
        enable = true;
        encrypt = true;
        disk = disk;
      };
    };
    services = {
      k3s = {
        enable = true;
        prepare = {
          cilium = true;
        };
        services = {
          kube-proxy = true;
          flux = true;
          servicelb = false;
          traefik = false;
          local-storage = false;
          metrics-server = false;
          coredns = false;
          flannel = false;
        };
        bootstrap = {
          helm = {
            enable = true;
            completedIf = "get CustomResourceDefinition -A | grep -q 'cilium.io'";
            helmfile = "/etc/k3s/helmfile.yaml";
          };
        };
        addons = {
          minio = {
            enable = true;
            credentialsFile = config.age.secrets.minio-credentials.path;
            buckets = ["volsync" "postgres"];
            dataDir = ["/mnt/backup/minio"];
          };
        };
      };
      kvm = {
        enable = true;
        platform = "${cpu}";
        user = "${user}";
      };
    };
  };

  boot.initrd.luks.devices."crypt_01" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_1TB_S626NZFR300XXXX-part1";
    preLVM = true;
    keyFile = "/disk.key";
    allowDiscards = true;
    fallbackToPassword = true;
  };

  boot.initrd.luks.devices."crypt_02" = {
    device = "/dev/disk/by-id/ata-WDC_WDS100T1R0A-68A4W0_212507A0XXXX-part1";
    preLVM = true;
    keyFile = "/disk.key";
    allowDiscards = true;
    fallbackToPassword = true;
  };
  
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-label/data01";
    fsType = "btrfs";
    options = ["defaults" "noatime" "compress=zstd" "subvol=@data"];
    neededForBoot = true; # gitea and minio store data here so ensure to first mount the drive
  };
  
  services.gitea = {
    enable = true;
    lfs.enable = true;
    stateDir = "/mnt/backup/gitea";
    useWizard = false; # broken
    group = "data";
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
      actions = {
        ENABLED = true;
      };
    };
  };

  powerManagement = {
    cpuFreqGovernor = "ondemand";
    cpufreq.max = cpufreqmax;
  };

  environment = {
    systemPackages = with pkgs; [
      gnutar
      ser2net
      par2cmdline
      rsync
      gzip
    ];
  };

  users = {
    groups = {
      data = { 
        name = "data"; 
        members = ["${user}"]; 
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
        openssh.authorizedKeys.keyFiles = [
          ./secrets/ssh.server02.lan.pub
        ];
      };
      root = {
        hashedPasswordFile = config.sops.secrets.user-password.path;
      };
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      ${user} = import ./home.nix;
    };
  };

  # TODO why do we need to fix the folder permission of mapped age secrets?
  systemd.tmpfiles.rules = [
    "d /mnt/backup 0775 root data -" # must be owned by root to solve gitea folder transition issues!
    "d /opt/k3s 0775 ${user} data -"
    "d /opt/k3s/data 0775 ${user} data -"
    "d /home/${user}/.config 0775 ${user} data -"
    "d /home/${user}/.config/sops 0775 ${user} data -"
    "d /home/${user}/.config/sops/age 0775 ${user} data -"
    "d /home/${user}/.kube 0775 ${user} data -"
    "d /var/lib/rancher/k3s/server/manifests 0775 root data -"
    "L /home/${user}/.kube/config  - - - - /etc/rancher/k3s/k3s.yaml"
    "L /var/lib/rancher/k3s/server/manifests/flux.yaml - - - - /etc/k3s/flux.yaml"
    "L /var/lib/rancher/k3s/server/manifests/flux-git-auth.yaml - - - - ${config.age.secrets.flux-git-auth.path}"
    "L /var/lib/rancher/k3s/server/manifests/flux-sops-age.yaml - - - - ${config.age.secrets.flux-sops-age.path}"                                  
    "L /var/lib/rancher/k3s/server/manifests/00-coredns-custom.yaml - - - - /etc/k3s/coredns-custom.yaml" # use 00- prefix to deploy this first                                 
  ];
  
  # required for deploy-rs
  nix.settings.trusted-users = [ "root" "${user}" ];

  # NOTE: we use the ssh key not the git key
  # git url schmeas: 
  # - 'git@server02.lan:r/gitops-homelab.git'
  # - 'ssh://git@server02.lan/home/git/r/gitops-homelab.git'
  # - 'ssh://git@server02.lan/~/r/gitops-homelab.git' => ~ is not supported in flux git repo url!
  # flux git secret:
  # 1. flux create secret git flux-git-auth --url="ssh://git@${domain}/~/r/gitops-homelab.git" --private-key-file={{ .PRIVATE_SSH_KEYFILE }} --export > flux-git-secret.yaml
  # 2. manually change the knwon_hosts to `ssh-keyscan -p 22 ${domain}` ssh-ed25519 output
  # 3. encrypt yaml with age
  environment.etc."k3s/flux.yaml" = {
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
        url: ssh://gitea@${domain}/r/nixos-k3s.git
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

  environment.etc."k3s/helmfile.yaml" = {
    mode = "0750";
    text = ''
      repositories:
        - name: coredns
          url: https://coredns.github.io/helm
        - name: cilium
          url: https://helm.cilium.io
      releases:
        - name: cilium
          namespace: kube-system
          # renovate: repository=https://helm.cilium.io
          chart: cilium/cilium
          version: 1.16.0
          values: ["${../../../kubernetes/core/networking/cilium/operator/helm-values.yaml}"]
          wait: true
        - name: coredns
          namespace: kube-system
          # renovate: repository=https://coredns.github.io/helm
          chart: coredns/coredns
          version: 1.32.0
          values: ["${../../../kubernetes/core/networking/coredns/app/helm-values.yaml}"]
          wait: true
    '';
  };
  
  # NOTE this config map is optional used by k3s coredns see https://github.com/k3s-io/k3s/blob/master/manifests/coredns.yaml
  environment.etc."k3s/coredns-custom.yaml" = {
    mode = "0750";
    text = ''  
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: coredns-custom
        namespace: kube-system
      data:
        domain.server: |
          ${domain}:53 {
            errors
            health
            ready
            hosts {
              ${ip} ${domain}
              fallthrough
            }
            prometheus :9153
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance          
          }
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

  systemd.services.minio-backup = {
    serviceConfig.Type = "oneshot";
    path = [
      pkgs.findutils
      pkgs.gnutar
      pkgs.gzip
    ];
    script = ''
      echo "Start minio backup now"
      mkdir -p /mnt/backup/${domain}/rsync/data/minio
      mkdir -p /mnt/backup/${domain}/rsync/log
      mkdir -p /mnt/backup/${domain}/archiv
      ${pkgs.rsync}/bin/rsync \
        -av \
        --delete \
        --ignore-missing-args \
        --log-file="/mnt/backup/${domain}/rsync/log/$(date +"%Y-%m-%d_%H-%M-%S").log" \
        --exclude "volsync/monerod" \
        /mnt/backup/minio/ /mnt/backup/${domain}/rsync/data/minio/
      export BACKUP_ARCHIVE_NAME="backup_$(date +%Y-%m-%d).tar.gz"
      tar -I 'gzip --fast' -cf "/mnt/backup/${domain}/archiv/$BACKUP_ARCHIVE_NAME" /mnt/backup/${domain}/rsync/data/minio
      find /mnt/backup/${domain}/archiv/*.tar.gz* -mtime +15 -exec rm {} \;
      echo "minio backup completed"
    '';
  };

  systemd.timers.minio-backup = {
    wantedBy = [ "timers.target" ];
    partOf = [ "minio-backup.service" ];
    timerConfig.OnCalendar = [ "Mon 06:00:00" ];
  };
  
  systemd.services.opnsense-kvm-backup = {
    serviceConfig.Type = "oneshot";
    path = [
      pkgs.libvirt
      pkgs.qemu_full
    ];
    script = ''
      echo "Start opnsense-kvm backup now"
      export HOME="/tmp/virtnbdbackup"
      mkdir -p "$HOME"
      mkdir -p /mnt/backup/${domain}/kvm/opnsense
     
      # NOTE: The following require qemu format v3
      # export BACKUP_DEST="/mnt/backup/${domain}/kvm/opnsense/$(date +%Y-%m)"
      # ${pkgs.virtnbdbackup}/bin/virtnbdbackup --uri qemu:///system -d terraform-opnsense -l auto -o $BACKUP_DEST -n
      # find /mnt/backup/${domain}/kvm/opnsense/* -type d -maxdepth 1 -mtime +90 -exec rm -r {} \;
      
      export BACKUP_DEST="/mnt/backup/${domain}/kvm/opnsense/$(date +%Y-%m-%d)"
      ${pkgs.virtnbdbackup}/bin/virtnbdbackup --uri qemu:///system -d terraform-opnsense -l copy -o $BACKUP_DEST -n
      find /mnt/backup/${domain}/kvm/opnsense/* -maxdepth 0 -type d -mtime +30 -exec rm -r {} \;

      rm -rf /mnt/backup/${domain}/kvm/opnsense/latest 
      ${pkgs.virtnbdbackup}/bin/virtnbdrestore -i $BACKUP_DEST -o /mnt/backup/${domain}/kvm/opnsense/latest -n
      
      echo "opnsense-kvm backup completed"
    '';
  };

  systemd.timers.opnsense-kvm-backup = {
    wantedBy = [ "timers.target" ];
    partOf = [ "opnsense-kvm-backup.service" ];
    timerConfig.OnCalendar = [ "Tue 06:00:00" ];
  };
}
