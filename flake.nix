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
            libGL
            xorg.libX11
            xorg.libXrandr
            xorg.libXi
            xorg.libXcursor
            xorg.libXinerama
            xorg.libXext
            xorg.libxcb
            xorg.libXfixes
            mesa
            vulkan-loader # optional
            zig
            rocmPackages.clang
            gcc
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.gcc
            pkgs.raylib
            pkgs.libGL
            pkgs.xorg.libX11
            pkgs.xorg.libXrandr
            pkgs.xorg.libXi
            pkgs.xorg.libXcursor
            pkgs.xorg.libXinerama
            pkgs.xorg.libXext
            pkgs.xorg.libxcb
            pkgs.xorg.libXfixes
            pkgs.mesa
            pkgs.vulkan-loader
          ];

          shellHook = ''
            echo "🔧 Zepto dev shell (Nixpkgs Unstable)"
          '';
        };
      });
}

