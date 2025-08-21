{
  description = "Flake Dependencies for Zepto";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "clang-zig-shell";

          buildInputs = with pkgs; [
            zig
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.zig
          ];

          shellHook = ''
            echo "🔧 Zepto dev shell (Nixpkgs Unstable)"
          '';
        };
      });
}

