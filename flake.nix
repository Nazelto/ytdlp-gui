{
  description = "cpp/xmake flake template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystem = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnsupportedSystem = true;
              problems.handlers.python3.broken = "warn";
              problems.handlers.python3-x86_64-w64-mingw32.broken = "warn";
            };
          };
          xmakePackages = pkgs.callPackage ./nix/xmake.nix { useLLVM = true; };
          fileset = [
            ./xmake.lua
            ./src
          ];
          default = xmakePackages {
            pname = "ytdlp-gui";
            version = "beta";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions fileset;
            };
            nativeBuildInputs = with pkgs; [
              qt6.wrapQtAppsHook
            ];
            buildInputs = with pkgs; [
              qt6.qtbase
              xmake
              pkg-config
              qt6.wrapQtAppsHook
            ];
            postInstall = ''
              mkdir -p "$out/bin/tools"
              cp "${pkgs.yt-dlp}/bin/yt-dlp" "$out/bin/tools/yt-dlp"
              cp "${pkgs.ffmpeg}/bin/ffmpeg" "$out/bin/tools/ffmpeg"
            '';
            preFixup = ''
              qtWrapperArgs+=(
                --prefix PATH : "${
                  pkgs.lib.makeBinPath [
                    pkgs.yt-dlp
                    pkgs.ffmpeg
                  ]
                }"
              )
            '';
          };
          win = pkgs.callPackage ./nix/window.nix { };
          ytdlp_windows = pkgs.fetchurl {
            url = "https://github.com/yt-dlp/yt-dlp/releases/download/2026.07.04/yt-dlp.exe";
            hash = "sha256-Uv48Jtz3H73IW1KFiQILsLjjgxVc+oG2TdRHu+NeJLg=";
          };
          ffmpeg_windows = pkgs.fetchurl {
            url = "https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl-shared.zip";
            hash = "sha256-GLU2CuiYfGNKERdpO5CMlnKXaZaBzzQuiqj9kuugbBo=";
          };
          windows = win {
            pname = "ytdlp-gui";
            version = "alpha";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./xmake.lua
                ./src
              ];
            };
            ytdlpWindows = ytdlp_windows;
            ffmpegWindows = ffmpeg_windows;
          };
          windowsMsi =
            pkgs.callPackage ./nix/window-msi.nix
              {
                app = windows;
              }
              {
                pname = "ytdlp-gui";
                version = "alpha";
              };
        in
        pkgs.lib.optionalAttrs (builtins.all builtins.pathExists fileset) {
          default = default;
          windows = windows;
          windowsMsi = windowsMsi;
        }
      );
      devShells = forAllSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          fileset = [
            ./xmake.lua
            ./src
          ];
        in
        {
          default =
            (pkgs.mkShell.override {
              stdenv = pkgs.llvmPackages.stdenv;
            })
              {
                inputsFrom = pkgs.lib.optionals (builtins.all builtins.pathExists fileset) [
                  self.packages.${system}.default
                ];
                packages = with pkgs; [
                  llvmPackages.clang-tools
                  lua-language-server
                  xmake
                  wineWow64Packages.stableFull
                  winetricks
                ];
                shellHook = ''
                  export XMAKE_GLOBALDIR="$PWD/.xmake-global"
                  export WINEPREFIX="$PWD/.wine64-test"
                  export WINEARCH=win64
                '';
              };
        }
      );
    };
}
