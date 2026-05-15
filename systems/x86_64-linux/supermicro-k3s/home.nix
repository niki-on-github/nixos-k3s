{ inputs, ... }: {
  imports = [
    inputs.self.homeManagerRoles.k3s
  ];

  home.stateVersion = "24.11";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "git.server02.lan" = {
        port = 222;
        hostname = "git.server02.lan";
        user = "git";
        identityFile = "~/.ssh/git.server02.lan";
      };
    };
  };
}
