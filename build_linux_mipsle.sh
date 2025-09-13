#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
NC='\033[0m' # 无颜色

# 创建构建目录
mkdir -p ./build

# 获取当前版本
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")

# 设置目标操作系统和架构
GOOS="linux"
GOARCH="mipsle"

# 设置输出二进制文件名
BINARY_NAME="komari-agent-${GOOS}-${GOARCH}"

# 设置编译参数
build_args="-trimpath -ldflags=-s -ldflags=-w -ldflags=-X=github.com/komari-monitor/komari-agent/update.CurrentVersion=${VERSION}"

# 添加MIPS架构特定参数
echo -e "Adding specific flags for MIPS architecture ($GOARCH)..."
export GOMIPS=softfloat

# 显示开始编译信息
echo -e "Building for $GOOS/$GOARCH..."

# 执行编译命令
env GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 go build $build_args -o "./build/$BINARY_NAME"

# 检查编译结果
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to build for $GOOS/$GOARCH${NC}"
exit 1
else
  echo -e "${GREEN}Successfully built $BINARY_NAME${NC}"
echo -e "\n${GREEN}Build completed successfully.${NC}"
echo -e "\nBinary is in the ./build directory."
exit 0
fi