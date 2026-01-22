{
  description = "Flake Dependencies for Zepto";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.11/";
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
            zls
            alpine
            lldb_21
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.zig_0_15 ];

          shellHook = ''
            echo "🔧 Zepto dev shell (Nixpkgs Unstable)"
          '';
        };
      });
}

