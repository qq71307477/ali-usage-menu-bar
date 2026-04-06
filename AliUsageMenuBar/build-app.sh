#!/bin/bash
set -e

echo "构建 AliUsageMenuBar..."
swift build -c release

BUILD_PATH=".build/release/AliUsageMenuBar"

if [ -f "$BUILD_PATH" ]; then
    echo "构建成功: $BUILD_PATH"
    echo ""
    echo "运行: swift run"
else
    echo "构建失败"
    exit 1
fi