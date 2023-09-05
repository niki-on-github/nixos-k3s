{ config, lib, pkgs, inputs, ... }:
let
  user = "nix";
in
{
  imports = with inputs.self.nixosModules; [
    inputs.self.nixosRoles.k3s
    inputs.home-manager.nixosModules.home-manager
    boot-encrypted
  ];

  disko.devices = inputs.personalModules.nixosModules.encrypted-system-disk-template {
    lib = lib;
    disks = [ "/dev/disk/by-id/ata-SanDisk_SDSSDH3_512G_191805802811" ];
  };

  age.secrets = {
    flux-git-auth.file = ./secrets/flux-git-auth.yaml.age;
    flux-sops-age.file = ./secrets/flux-sops-age.yaml.age;
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.sops.yaml;
    secrets.user-password.neededForUsers = true;
  };

  users = {
    users = {
      ${user} = {
        isNormalUser = true;
        description = "nix user";
        createHome = true;
        # use `mkpasswd -m sha-512 | tr -d '\n'` to get the password hash for your sops file
        passwordFile = config.sops.secrets.user-password.path;
        home = "/home/${user}";
        extraGroups = [
          "audit"
          "sshusers"
          "storage"
          "wheel"
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

  # required for deploy-rs
  nix.settings.trusted-users = [ "root" "${user}" ];

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
        url: ssh://git@git.server01.lan:222/r/gitops-homelab.git
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

  system.activationScripts.flux.text = ''
    mkdir -p /var/lib/rancher/k3s/server/manifests
    ln -sf /etc/flux.yaml /var/lib/rancher/k3s/server/manifests/flux.yaml
    ln -sf /run/agenix/flux-git-auth /var/lib/rancher/k3s/server/manifests/flux-git-auth.yaml
    ln -sf /run/agenix/flux-sops-age /var/lib/rancher/k3s/server/manifests/flux-sops-age.yaml
  '';
}
