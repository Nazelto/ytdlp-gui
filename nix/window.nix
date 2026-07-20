{ pkgs, ... }:

{
  pname,
  version,
  src,
  nativeBuildInputs ? [ ],
  xmakeFlags ? [ ],
  ytdlpWindows,
  ffmpegWindows,
  ...
}@args:

let
  mingw = pkgs.pkgsCross.mingwW64;
  msys2Mirror = "https://repo.msys2.org/mingw/mingw64";
  fetchMsys2 = filename: hash:
    pkgs.fetchurl {
      url = "${msys2Mirror}/${filename}";
      inherit hash;
    };
  msys2Packages = [
    (fetchMsys2 "mingw-w64-x86_64-brotli-1.2.0-1-any.pkg.tar.zst" "sha256-9fL35yOgg3gkHRXwU3OGlQwaSOLYK8R77dYyvWGFKro=")
    (fetchMsys2 "mingw-w64-x86_64-bzip2-1.0.8-3-any.pkg.tar.zst" "sha256-ZT7JfBjcE5ypTitLnRYam02ed86xjfsGTrle8qcRcbY=")
    (fetchMsys2 "mingw-w64-x86_64-dbus-1.16.2-3-any.pkg.tar.zst" "sha256-Y1HiMs6yGKET9YuW6Cf1lbrh3SrnwHUlAu/FujO8cPw=")
    (fetchMsys2 "mingw-w64-x86_64-double-conversion-3.4.0-1-any.pkg.tar.zst" "sha256-rjod+JIOz0ll5yQZ6xAfCogH+5sG1XMm1sWkmG/FrMI=")
    (fetchMsys2 "mingw-w64-x86_64-expat-2.8.2-1-any.pkg.tar.zst" "sha256-nyVVDHOLdpUWT06iN69AUS18Y7TNl6pBfz4CFJMKyk8=")
    (fetchMsys2 "mingw-w64-x86_64-freetype-2.14.3-1-any.pkg.tar.zst" "sha256-s+MQ9FfJA0j9FLjBCF6cA2AW0WiBKmV/7CH0lvfj3pk=")
    (fetchMsys2 "mingw-w64-x86_64-gcc-libs-16.1.0-5-any.pkg.tar.zst" "sha256-qlYPVDjDW3HD57JP1b7LygKPcMW00fFpeob/gP7JR9o=")
    (fetchMsys2 "mingw-w64-x86_64-gettext-runtime-1.0-1-any.pkg.tar.zst" "sha256-vmjX8mBjMoS5EMWIxtgu4wSoHIgXpobSzZ34P4csJ68=")
    (fetchMsys2 "mingw-w64-x86_64-glib2-2.88.2-1-any.pkg.tar.zst" "sha256-WFX7JsqGQFoYJuKns1wGiGAiW85qU8aY9wlBBa0lJxo=")
    (fetchMsys2 "mingw-w64-x86_64-graphite2-1.3.15-1-any.pkg.tar.zst" "sha256-atINbBblWffEsG/nEkjhIBx+30lNBOVyHtf5s/f9H3Q=")
    (fetchMsys2 "mingw-w64-x86_64-harfbuzz-14.2.1-1-any.pkg.tar.zst" "sha256-03hGSlf1LlLGAWgiv3GMbZPCeDxPd48raF2mAIqWljI=")
    (fetchMsys2 "mingw-w64-x86_64-icu-78.3-3-any.pkg.tar.zst" "sha256-tegFzoEgLkjVK/WYNFrFw7oinwF/A+sjhYRSsiNJw5E=")
    (fetchMsys2 "mingw-w64-x86_64-libb2-0.98.1-3-any.pkg.tar.zst" "sha256-PImPCMXxniXcbX45qja28yMUHw5ixcUPCJzT+JcRhUw=")
    (fetchMsys2 "mingw-w64-x86_64-libffi-3.7.1-1-any.pkg.tar.zst" "sha256-oBbfE8Z6BDiguUJn8pEcaP1Ncha01F+6x6Zq9B/nj0Q=")
    (fetchMsys2 "mingw-w64-x86_64-libiconv-1.19-1-any.pkg.tar.zst" "sha256-IeM00JEfJd510+GOBpdki87PqWWCVtYAytCCfXGcLzU=")
    (fetchMsys2 "mingw-w64-x86_64-libjpeg-turbo-3.2.0-1-any.pkg.tar.zst" "sha256-7z9Vz1I4qARcjzd5bXMOSl7mGdKcqSVKqmJFbltbflE=")
    (fetchMsys2 "mingw-w64-x86_64-libpng-1.6.58-1-any.pkg.tar.zst" "sha256-2K5gZvmbOgS4O4ATtVSiaiBdfmhYC4CCPBc+0EW6dqU=")
    (fetchMsys2 "mingw-w64-x86_64-libsystre-1.0.2-2-any.pkg.tar.zst" "sha256-81G94yY36HUW261hpcd8Y6rgcJJzaTxa7m4KhTPWjxQ=")
    (fetchMsys2 "mingw-w64-x86_64-libtre-0.9.0-2-any.pkg.tar.zst" "sha256-xAUVCNBjJY4eAt0pYV7bfXPFxfWCrkJ5X92S593OUGs=")
    (fetchMsys2 "mingw-w64-x86_64-libwinpthread-14.0.0.r190.g96fb1bff7-1-any.pkg.tar.zst" "sha256-UuhNvO9zUuPOSqBKJNMg2AObDdxZsGA8zqAPGpdeg3Q=")
    (fetchMsys2 "mingw-w64-x86_64-md4c-0.5.3-1-any.pkg.tar.zst" "sha256-IlBc76ShWnne1t6nJyND0nOJpbA6YQHTyrJ85q3GzHQ=")
    (fetchMsys2 "mingw-w64-x86_64-mpdecimal-4.0.1-3-any.pkg.tar.zst" "sha256-jafn94Q08YhmTE0necA+p6gPf1g3oRWDSrc0s1KmE+U=")
    (fetchMsys2 "mingw-w64-x86_64-ncurses-6.6-4-any.pkg.tar.zst" "sha256-e/UVlEHQAmIIXSYZ9sJod+p1ldTa/GhAY3xsX8zaXPU=")
    (fetchMsys2 "mingw-w64-x86_64-openssl-3.6.3-1-any.pkg.tar.zst" "sha256-gt5/+IYRI3T/rp57PIQ8gjQuGYVD+wJHkEFu9WQ0/p8=")
    (fetchMsys2 "mingw-w64-x86_64-pcre2-10.47-1-any.pkg.tar.zst" "sha256-fJ481HrwKglsDBgQ0QIfY8X7HSLb7JH6AZ2LN+2gDZg=")
    (fetchMsys2 "mingw-w64-x86_64-python-3.14.6-1-any.pkg.tar.zst" "sha256-jr0i3HALfZA5w5PB2ojk8NgqRFwF7coTUdlsDBH00/E=")
    (fetchMsys2 "mingw-w64-x86_64-python-packaging-26.2-1-any.pkg.tar.zst" "sha256-Pmim7AJHAMkDLA8oexxLXBW0R1dz0hlD4EEL7mG/JNA=")
    (fetchMsys2 "mingw-w64-x86_64-qt6-base-6.11.1-1-any.pkg.tar.zst" "sha256-aVenelU5uknYahuye7eJ10PeY90f8flsAu24Y7HyE5U=")
    (fetchMsys2 "mingw-w64-x86_64-sqlite3-3.53.3-1-any.pkg.tar.zst" "sha256-ldsPPAM9JDeO6IIeLH7QocQcKwDo5lGAGi690EuthhY=")
    (fetchMsys2 "mingw-w64-x86_64-tcl-8.6.18-1-any.pkg.tar.zst" "sha256-2VKJMA/Y4WvVyyQbmSiiVmla7r7KKIXe7zMmzUpNW6g=")
    (fetchMsys2 "mingw-w64-x86_64-tk-8.6.18-1-any.pkg.tar.zst" "sha256-Qqp5li4Wed1V6T95ol3B5QxyNfFDq1AbPsaN69DTKj4=")
    (fetchMsys2 "mingw-w64-x86_64-tzdata-2026c-1-any.pkg.tar.zst" "sha256-UC5vjmXFVOcX9sdJ3LtwzJuF7ZSwHBUcJqDCUjXmPfI=")
    (fetchMsys2 "mingw-w64-x86_64-vulkan-headers-1~1.4.350.1-1-any.pkg.tar.zst" "sha256-O2eEWnmhcJBeP/qlnYTB+F7ddSE6gU4/kG62gnfzeZM=")
    (fetchMsys2 "mingw-w64-x86_64-vulkan-loader-1~1.4.350.1-1-any.pkg.tar.zst" "sha256-qzcazDnJY0Kw8DrtwHgFHsBZ4eoLQZ64ZSaHaojNjMo=")
    (fetchMsys2 "mingw-w64-x86_64-wineditline-2.208-1-any.pkg.tar.zst" "sha256-3+f6tmYy7s7Mc9hAU+rivo3SFG7O/g/CEzJ3cGCE1+o=")
    (fetchMsys2 "mingw-w64-x86_64-xz-5.8.3-1-any.pkg.tar.zst" "sha256-B1v68cdSfy/dAq1blzN44ejUJrp7YU8SLOvYGo/l0cE=")
    (fetchMsys2 "mingw-w64-x86_64-zlib-1.3.2-2-any.pkg.tar.zst" "sha256-nnWEKgcLpkjphuEkJOHJLJ19dyAOhfajTutgCBny5pQ=")
    (fetchMsys2 "mingw-w64-x86_64-zstd-1.5.7-2-any.pkg.tar.zst" "sha256-Gt1nBbNEZk9qyhCMhfeatb3Z4RYmYrsGpM9Ao09uCQc=")
  ];
in
pkgs.stdenv.mkDerivation (
  {
    inherit pname version src;
    dontWrapQtApps = true;
    dontStrip = true;

    nativeBuildInputs =
      with pkgs;
      [
        gnutar
        pkg-config
        qt6.qtbase
        unzip
        xmake
        zstd
      ]
      ++ [ mingw.stdenv.cc ]
      ++ nativeBuildInputs;

    configurePhase = ''
      runHook preConfigure

      export HOME="$TMPDIR"
      export XMAKE_GLOBALDIR="$TMPDIR/xmake-global"

      mkdir -p "$TMPDIR/msys2-sdk"
      for package in ${pkgs.lib.escapeShellArgs msys2Packages}; do
        tar --zstd -xf "$package" -C "$TMPDIR/msys2-sdk"
      done

      export MSYS2_MINGW_PREFIX="$TMPDIR/msys2-sdk/mingw64"
      export PATH="$MSYS2_MINGW_PREFIX/bin:$PATH"
      export PKG_CONFIG_PATH="$MSYS2_MINGW_PREFIX/lib/pkgconfig"
      export CMAKE_PREFIX_PATH="$MSYS2_MINGW_PREFIX"

      cat > "$MSYS2_MINGW_PREFIX/bin/qmake" <<EOF
      #!${pkgs.runtimeShell}
      if [ "\$1" = "-query" ]; then
        cat <<QUERY
      QT_VERSION:6.11.1
      QT_INSTALL_PREFIX:$MSYS2_MINGW_PREFIX
      QT_INSTALL_ARCHDATA:$MSYS2_MINGW_PREFIX/share/qt6
      QT_INSTALL_DATA:$MSYS2_MINGW_PREFIX/share/qt6
      QT_INSTALL_DOCS:$MSYS2_MINGW_PREFIX/share/doc/qt6
      QT_INSTALL_HEADERS:$MSYS2_MINGW_PREFIX/include/qt6
      QT_INSTALL_LIBS:$MSYS2_MINGW_PREFIX/lib
      QT_INSTALL_LIBEXECS:$MSYS2_MINGW_PREFIX/share/qt6/bin
      QT_INSTALL_BINS:$MSYS2_MINGW_PREFIX/bin
      QT_INSTALL_TESTS:$MSYS2_MINGW_PREFIX/tests
      QT_INSTALL_PLUGINS:$MSYS2_MINGW_PREFIX/share/qt6/plugins
      QT_INSTALL_QML:$MSYS2_MINGW_PREFIX/share/qt6/qml
      QT_INSTALL_TRANSLATIONS:$MSYS2_MINGW_PREFIX/share/qt6/translations
      QT_INSTALL_CONFIGURATION:
      QT_INSTALL_EXAMPLES:$MSYS2_MINGW_PREFIX/share/qt6/examples
      QT_INSTALL_DEMOS:$MSYS2_MINGW_PREFIX/share/qt6/examples
      QT_HOST_BINS:${pkgs.qt6.qtbase}/libexec
      QT_HOST_LIBEXECS:${pkgs.qt6.qtbase}/libexec
      QT_HOST_DATA:$MSYS2_MINGW_PREFIX/share/qt6
      QMAKE_SPEC:win32-g++
      QMAKE_XSPEC:win32-g++
      QMAKE_MKSPECS:$MSYS2_MINGW_PREFIX/share/qt6/mkspecs
      QUERY
        exit 0
      fi
      echo "fake qmake only supports -query" >&2
      exit 1
      EOF
      chmod +x "$MSYS2_MINGW_PREFIX/bin/qmake"

      xmake f \
        -c \
        -p mingw \
        -a x86_64 \
        -m release \
        --toolchain=mingw \
        --mingw="${mingw.stdenv.cc}" \
        --cross=x86_64-w64-mingw32- \
        --cc=x86_64-w64-mingw32-gcc \
        --cxx=x86_64-w64-mingw32-g++ \
        --ld=x86_64-w64-mingw32-g++ \
        --qt="$MSYS2_MINGW_PREFIX" \
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

      mkdir -p "$out/bin/platforms" "$out/bin/tools"

      cp "$MSYS2_MINGW_PREFIX/bin/"*.dll "$out/bin/"
      cp "$MSYS2_MINGW_PREFIX/share/qt6/plugins/platforms/qwindows.dll" "$out/bin/platforms/"

      unzip -j "${ffmpegWindows}" "*/bin/ffmpeg.exe" -d "$out/bin/tools"
      cp "${ytdlpWindows}" "$out/bin/tools/yt-dlp.exe"

      runHook postInstall
    '';
  }
  // builtins.removeAttrs args [
    "xmakeFlags"
    "nativeBuildInputs"
    "ytdlpWindows"
    "ffmpegWindows"
  ]
)
