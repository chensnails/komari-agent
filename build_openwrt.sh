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

# 为mt7621芯片的OpenWrt系统构建二进制文件
# mt7621通常使用mipsle架构
GOOS="linux" 
GOARCH="mipsle" 
CGO_ENABLED=0 

# 设置输出二进制文件名
BINARY_NAME="komari-agent-openwrt-mt7621"

# 构建二进制文件
env GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X github.com/komari-monitor/komari-agent/update.CurrentVersion=${VERSION}" -o "./build/$BINARY_NAME"

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to build for OpenWrt (mt7621)${NC}"
  exit 1
else
  echo -e "${GREEN}Successfully built $BINARY_NAME${NC}"
  echo -e "\nBinary is in the ./build directory."
  echo -e "\nTo run on OpenWrt (mt7621):"
  echo -e "1. Copy the binary to your device: scp ./build/$BINARY_NAME root@<your-router-ip>:~/"
  echo -e "2. SSH into your router"
  echo -e "3. Make the binary executable: chmod +x ./$BINARY_NAME"
  echo -e "4. Run the agent: ./$BINARY_NAME -e <api-endpoint> -t <api-token>"
fi