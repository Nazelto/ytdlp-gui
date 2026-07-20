# yt-dlp GUI

一个基于 Qt Widgets 的 `yt-dlp` 图形界面，用于粘贴视频地址、选择保存目录并下载视频。

打包版本会自带 `yt-dlp` 和 `ffmpeg`。NixOS/Linux 版本从 nixpkgs 提供工具；Windows MSI 会把 `yt-dlp.exe`、`ffmpeg.exe`、Qt DLL 和 MSYS2 运行时 DLL 一起打进安装包。

## NixOS 用户

构建并运行原生 Linux 版本：

```bash
nix build
./result/bin/ytdlp-gui
```

进入开发环境：

```bash
nix develop
xmake
xmake run ytdlp-gui
```

Nix 构建会把辅助工具安装到：

```text
result/bin/tools/yt-dlp
result/bin/tools/ffmpeg
```

如果没有找到内置工具，程序会回退到从 `PATH` 中查找 `yt-dlp` 和 `ffmpeg`。

## Windows 用户

从 GitHub Releases 下载 `.msi` 安装包并运行安装。

默认安装目录：

```text
C:\Program Files\yt-dlp GUI
```

MSI 安装包包含：

```text
ytdlp-gui.exe
yt-dlp.exe
ffmpeg.exe
Qt 运行时 DLL
MSYS2 运行时 DLL
qwindows.dll
```

安装后打开 `yt-dlp GUI`，粘贴视频地址，选择保存目录，然后点击下载。

## 构建 Windows MSI

在 Linux/NixOS 上执行：

```bash
nix build .#windowsMsi
```

生成的安装包位置：

```text
result/ytdlp-gui-alpha.msi
```

Windows 构建使用：

- nixpkgs 提供的 Linux-hosted MinGW 编译器
- MSYS2 预编译 Qt/runtime 包，提供 Windows 目标端 headers、import libraries 和 DLL
- yt-dlp 官方发布的 `yt-dlp.exe`
- BtbN FFmpeg builds 提供的 `ffmpeg.exe`
- `msitools` 的 `wixl` 生成 MSI

## 用 Wine 测试 MSI

进入开发环境：

```bash
nix develop
```

创建干净的 64-bit Wine prefix：

```bash
wineserver -k || true
rm -rf .wine64-test
wineboot -u
grep '#arch' "$WINEPREFIX/system.reg"
```

应看到：

```text
#arch=win64
```

安装并运行：

```bash
nix build .#windowsMsi
wine msiexec /i result/ytdlp-gui-alpha.msi
wine "$WINEPREFIX/drive_c/Program Files/yt-dlp GUI/ytdlp-gui.exe"
```

卸载：

```bash
wine msiexec /x result/ytdlp-gui-alpha.msi
```

如果 Wine 报缺 DLL，重新构建 MSI 并重新安装。MSI 生成逻辑会把 Windows app 输出目录中的 `bin/*.dll` 全部写入安装包。

## Release Notes

### yt-dlp GUI alpha

- 新增 Qt Widgets 图形界面，可粘贴视频地址、选择保存目录并调用 `yt-dlp` 下载。
- 新增 NixOS/Linux 原生构建，构建产物自带 `yt-dlp` 和 `ffmpeg`。
- 新增 Windows x86_64 MSI 安装包，可在 Linux/NixOS 上通过 Nix 构建。
- Windows 构建改用 MSYS2 预编译 Qt/runtime 包，避免 nixpkgs Qt 交叉编译依赖链中的 GLib/SQLite/Tcl 构建问题。
- MSI 会打包 `ytdlp-gui.exe`、Qt DLL、MSYS2 runtime DLL、`qwindows.dll`、`yt-dlp.exe` 和 `ffmpeg.exe`。
- 开发环境加入 Wine 和 Winetricks，方便本地测试 MSI 安装与运行。
