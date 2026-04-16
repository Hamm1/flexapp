{
  description = "A development shell for Zig";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        libraries = with pkgs; [
          gtk3
          glib
          dbus
        ];
        packages = with pkgs; [
          pkg-config
          dbus
          glib
          gtk3
        ];
      in
      {
        packages = {
          test = pkgs.writeShellScriptBin "zig-test" ''
            zig test src/root.zig
          '';

          build = pkgs.writeShellScriptBin "zig-build" ''
            zig build -Doptimize=ReleaseFast
          '';

          safe = pkgs.writeShellScriptBin "zig-safe" ''
            zig build -Doptimize=ReleaseSafe
          '';

          build-windows = pkgs.writeShellScriptBin "zig-build-windows" ''
            zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast
          '';

          build-windows-safe = pkgs.writeShellScriptBin "zig-build-windows-safe" ''
            zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
          '';

          clean = pkgs.writeShellScriptBin "clean" ''
            rm -rf flake.lock zig-out .zig-cache out
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = packages ++ [
            self.packages.${system}.test
            self.packages.${system}.build
            self.packages.${system}.safe
            self.packages.${system}.build-windows
            self.packages.${system}.build-windows-safe
            self.packages.${system}.clean
          ];
          nativeBuildInputs = with pkgs; [
            zig
            docker
            python314
            uv
            mise
            neovim
          ];
          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
            echo "Flexapp Development Environment"
            echo ""
            echo "Available commands:"
            echo "  nix run .#test                - Run Zig tests (zig-test)"
            echo "  nix run .#build               - Build with ReleaseFast (zig-build)"
            echo "  nix run .#safe                - Build with ReleaseSafe (zig-safe)"
            echo "  nix run .#build-windows       - Build for Windows (ReleaseFast) (zig-build-windows)"
            echo "  nix run .#build-windows-safe  - Build for Windows (ReleaseSafe) (zig-build-windows-safe)"
            echo "  nix run .#clean               - Clean Directory (clean)"
          '';
        };
      });
}