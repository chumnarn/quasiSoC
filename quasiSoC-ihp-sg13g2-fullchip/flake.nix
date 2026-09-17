{
  nixConfig = {
    extra-substituters = [ "https://nix-cache.fossi-foundation.org" ];
    extra-trusted-public-keys = [
      "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
    ];
  };
  inputs.librelane.url = "github:librelane/librelane/3.0.0";
  outputs = { self, librelane, ... }:
    let
      nix-eda = librelane.inputs.nix-eda;
      devshell = librelane.inputs.devshell;
      nixpkgs = nix-eda.inputs.nixpkgs;
    in {
      legacyPackages = nix-eda.forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ nix-eda.overlays.default devshell.overlays.default librelane.overlays.default ];
      });
      devShells = nix-eda.forAllSystems (system:
        let pkgs = self.legacyPackages.${system};
        in {
          default = pkgs.librelane-shell.override {
            extra-packages = with pkgs; [ git gnumake gnugrep gawk iverilog verilator gtkwave fusesoc ];
            extra-python-packages = ps: with ps; [ pyyaml cocotb docopt pillow ];
          };
        });
    };
}
