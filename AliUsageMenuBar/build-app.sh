#!/bin/bash
set -e

echo "构建 Release 版本..."
swift build -c release

APP_NAME="阿里云百炼用量.app"
APP_DIR=".build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "创建 .app 包结构..."
rm -rf ".build/$APP_NAME"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "复制可执行文件..."
cp ".build/release/AliUsageMenuBar" "$MACOS_DIR/"

echo "复制 Info.plist..."
cp "Info.plist" "$CONTENTS_DIR/"

echo "复制图标..."
if [ -d "Sources/AliUsageMenuBar/Assets.xcassets" ]; then
    # 尝试使用 iconutil 生成 icns
    ICONSET_DIR="/tmp/aliusagemenubar.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    # 复制图标文件
    ICON_SRC="Sources/AliUsageMenuBar/Assets.xcassets/AppIcon.appiconset"
    if [ -f "$ICON_SRC/icon_256x256.png" ]; then
        cp "$ICON_SRC/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_16x16@2x.png" "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_32x32@2x.png" "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_128x128@2x.png" "$ICONSET_DIR/icon_128x128@2x.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_256x256@2x.png" "$ICONSET_DIR/icon_256x256@2x.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png" 2>/dev/null || true
        cp "$ICON_SRC/icon_512x512@2x.png" "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null || true

        iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || true
        rm -rf "$ICONSET_DIR"
    fi
fi

# 如果没有图标，使用系统默认
if [ ! -f "$RESOURCES_DIR/AppIcon.icns" ]; then
    echo "使用默认图标..."
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || true
fi

echo "复制 scripts 目录..."
SCRIPTS_SRC="../scripts"
if [ -d "$SCRIPTS_SRC" ]; then
    cp -r "$SCRIPTS_SRC" "$RESOURCES_DIR/scripts"
    echo "scripts 目录已复制"
else
    echo "警告: 找不到 scripts 目录 ($SCRIPTS_SRC)"
fi

echo ""
echo "✅ 构建完成！"
echo ""
echo "应用位置: $(pwd)/.build/$APP_NAME"
echo ""

# 签名
echo "签名应用..."
codesign --force --deep --sign - ".build/$APP_NAME" 2>/dev/null || true

echo "安装到 Applications:"
echo "  cp -r \".build/$APP_NAME\" /Applications/"
echo ""
echo "或直接双击运行:"
echo "  open \".build/$APP_NAME\""