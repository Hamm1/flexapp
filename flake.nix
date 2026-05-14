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
            ${pkgs.zig}/bin/zig test src/root.zig
          '';

          test-fast = pkgs.writeShellScriptBin "zig-test-fast" ''
            ${pkgs.zig}/bin/zig test src/root.zig -OReleaseFast
          '';
          test-safe = pkgs.writeShellScriptBin "zig-test-safe" ''
            ${pkgs.zig}/bin/zig test src/root.zig -OReleaseSafe
          '';

          build = pkgs.writeShellScriptBin "zig-build" ''
            ${pkgs.zig}/bin/zig build -Doptimize=ReleaseFast
          '';

          safe = pkgs.writeShellScriptBin "zig-safe" ''
            ${pkgs.zig}/bin/zig build -Doptimize=ReleaseSafe
          '';

          build-windows = pkgs.writeShellScriptBin "zig-build-windows" ''
            ${pkgs.zig}/bin/zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast
          '';

          build-windows-safe = pkgs.writeShellScriptBin "zig-build-windows-safe" ''
            ${pkgs.zig}/bin/zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
          '';

          clean = pkgs.writeShellScriptBin "clean" ''
            rm -rf zig-out .zig-cache out zig-pkg
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
            # Bootstrap LazyVim if not already configured
            _nvim_cfg="$HOME/.config/nvim"
            _lsp="$_nvim_cfg/lua/plugins/lsp.lua"
            _diag="$_nvim_cfg/after/plugin/diagnostics.lua"

            if [ ! -f "$_lsp" ] && [ ! -f "$_diag" ]; then
              echo "Setting up LazyVim..."
              rm -rf "$_nvim_cfg"
              git clone https://github.com/LazyVim/starter.git "$_nvim_cfg"
              rm -rf "$_nvim_cfg/.git"

              git clone --depth 1 https://github.com/Hamm1/devbox /tmp/devbox-cfg
              mkdir -p "$_nvim_cfg/lua/plugins" "$_nvim_cfg/after/plugin"
              cp /tmp/devbox-cfg/lsp.lua "$_lsp"
              cp /tmp/devbox-cfg/diagnostics.lua "$_diag"
              rm -rf /tmp/devbox-cfg

              echo "LazyVim configured."
            fi
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