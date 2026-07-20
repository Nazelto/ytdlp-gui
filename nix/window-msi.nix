{
  pkgs,
  app,
  ...
}:

{
  pname,
  version,
  productName ? "yt-dlp GUI",
  manufacturer ? "ytdlp-gui",
  msiVersion ? "0.1.0",
  upgradeCode ? "8D275AA7-8A2B-4DC0-A3E3-4FAF51E0D28C",
  applicationFilesGuid ? "6CD5B82F-5C25-4D05-B4F9-3876721B3499",
  qtPlatformFilesGuid ? "285E5E6C-5472-4E7E-8B93-F0170F5CA81B",
  bundledToolFilesGuid ? "7DFD67E0-7D0D-495F-A6C1-FE76E0901D51",
}:

pkgs.stdenvNoCC.mkDerivation {
  inherit pname version;

  nativeBuildInputs = [
    pkgs.msitools
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    files_xml="$PWD/files.xml"
    : > "$files_xml"

    file_id=0
    for file in ${app}/bin/*.dll; do
      file_id=$((file_id + 1))
      printf '            <File Id="RuntimeDll%d" Source="%s" />\n' "$file_id" "$file" >> "$files_xml"
    done

    cat > product.wxs <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product
    Id="*"
    Name="${productName}"
    Language="1033"
    Version="${msiVersion}"
    Manufacturer="${manufacturer}"
    UpgradeCode="${upgradeCode}">

    <Package
      InstallerVersion="500"
      Compressed="yes"
      InstallScope="perMachine"
      Platform="x64" />

    <MajorUpgrade
      DowngradeErrorMessage="A newer version of ${productName} is already installed." />

    <MediaTemplate EmbedCab="yes" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="${productName}">
          <Component Id="ApplicationFiles" Guid="${applicationFilesGuid}" Win64="yes">
            <File Id="YtdlpGuiExe" Source="${app}/bin/ytdlp-gui.exe" KeyPath="yes" />
$(cat "$files_xml")
          </Component>

          <Directory Id="PlatformsDir" Name="platforms">
            <Component Id="QtPlatformFiles" Guid="${qtPlatformFilesGuid}" Win64="yes">
              <File Id="QtWindowsPlatformDll" Source="${app}/bin/platforms/qwindows.dll" KeyPath="yes" />
            </Component>
          </Directory>

          <Directory Id="ToolsDir" Name="tools">
            <Component Id="BundledToolFiles" Guid="${bundledToolFilesGuid}" Win64="yes">
              <File Id="YtDlpExe" Source="${app}/bin/tools/yt-dlp.exe" KeyPath="yes" />
              <File Id="FfmpegExe" Source="${app}/bin/tools/ffmpeg.exe" />
            </Component>
          </Directory>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="DefaultFeature" Title="${productName}" Level="1">
      <ComponentRef Id="ApplicationFiles" />
      <ComponentRef Id="QtPlatformFiles" />
      <ComponentRef Id="BundledToolFiles" />
    </Feature>
  </Product>
</Wix>
EOF

    mkdir -p "$out"
    wixl -a x64 -o "$out/${pname}-${version}.msi" product.wxs

    runHook postInstall
  '';
}
