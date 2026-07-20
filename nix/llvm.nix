{ pkgs, ... }:
let
  llvm = pkgs.llvmPackages;
in
{
  pname,
  version,
  src,
  nativeBuildInputs ? [ ],
  BuildInputs ? [ ],
  xmakeFlags ? [ ],
  ...
}@args:
llvm.stdenv.mkDerivation (
  {

    nativeBuildInputs = [
      pkgs.xmake
      pkgs.pkg-config
    ]
    ++ nativeBuildInputs;
    configurePhase = ''
      runHook preConfigure

      export HOME="$TMPDIR"
      export XMAKE_GLOBALDIR="$TMPDIR/xmake-global"

      xmake f \
        -c \
        -m release \
        --toolchain=clang \
        ${pkgs.lib.escapeShellArgs xmakeFlags}

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      xmake -v
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      xmake install -o "$out"
      runHook postInstall
    '';
  }
  // builtins.removeAttrs args [ "xmakeFlags" ]

)
