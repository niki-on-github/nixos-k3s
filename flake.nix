{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.11";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    personalModules = {
      # url = "git+https://git.k8s.lan/r/nixos-modules.git";
      url = "git+http://10.0.1.11:3000/r/nixos-modules.git";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, deploy-rs, home-manager, sops-nix, agenix, nur, disko, personalModules, ... } @ inputs:
    let
      inherit (nixpkgs) lib;
      overlays = lib.flatten [
        nur.overlay
        personalModules.overrides
        personalModules.pkgs
      ];
      nixosDeployments = personalModules.utils.deploy.generateNixosDeployments {
        inherit inputs;
        path = ./systems;
        ssh-user = "nix";
        sharedModules = [
          { nixpkgs.overlays = overlays; }
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
