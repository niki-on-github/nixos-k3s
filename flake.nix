{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    agenix = {
      url = "github:ryantm/agenix";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };

    disko = {
      url = "github:nix-community/disko";
    };

    personalModules = {
      # Most of my personalModule code is available at https://github.com/niki-on-github/nixos-modules.git
      url = "git+https://git.k8s.lan/r/nixos-modules.git?submodules=1";
      # url = "git+http://10.0.1.11:3000/r/nixos-modules.git?submodules=1";
      # url = "path:/mnt/data-02/Work/Repos/private/nixos-modules";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        home-manager.follows = "home-manager";
        nur.follows = "nur";
      };
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, deploy-rs, home-manager, sops-nix, agenix, nur, disko, personalModules, ... } @ inputs:
    let
      inherit (nixpkgs) lib;
      overlays = lib.flatten [
        nur.overlays.default
        personalModules.overrides
        personalModules.pkgs
      ];
      nixosDeployments = personalModules.utils.deploy.generateNixosDeployments {
        inherit inputs nixpkgs overlays;
        path = ./systems;
        ssh-user = "root";
        sharedModules = [
          sops-nix.nixosModules.sops
          agenix.nixosModules.default
          disko.nixosModules.disko
        ];
      };
    in
    {
      inherit (personalModules) formatter devShells packages nixosModules homeManagerModules nixosRoles homeManagerRoles;
      inherit (nixosDeployments) nixosConfigurations deploy checks;
    };
}
