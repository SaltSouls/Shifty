{
    inputs = {
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    outputs = { self, flake-utils, nixpkgs, ... }:
        flake-utils.lib.eachDefaultSystem(system:
            let pkgs = import nixpkgs {
                inherit system;
            };
            in {
              devShells.default = pkgs.mkShell {
              packages = with pkgs; [lua54Packages.tl lua54Packages.cyan];
              shellHook = ''
                  echo "Welcome to the Shifty dev shell"
              '';
            };
          }
        );
}
