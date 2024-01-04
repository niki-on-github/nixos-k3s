{ inputs, ... }: {
  imports = [
    inputs.self.homeManagerRoles.k3s
  ];

  programs.ssh = {
    enable = true;
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
