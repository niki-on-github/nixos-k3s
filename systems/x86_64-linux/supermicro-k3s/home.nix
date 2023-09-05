{ inputs, ... }: {
  imports = with inputs.self.homeManagerModules; [
    general
    k3s
  ];

}
