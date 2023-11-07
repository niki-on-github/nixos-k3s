{ inputs, ... }: {
  imports = [
    inputs.self.homeManagerRoles.k3s
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "git.server01.lan" = {
        port = 222;
        hostname = "git.server01.lan";
        user = "git";
        identityFile = "~/.ssh/git.server01.lan";
      };
    };
  };
}
