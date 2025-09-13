#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
NC='\033[0m' # 无颜色

# 定义操作系统和架构列表
OS_LIST=("windows" "linux" "darwin" "freebsd")
ARCH_LIST=("amd64" "arm64" "386" "arm" "mips" "mipsle" "mips64" "mips64le")

# 创建构建目录
mkdir -p ./build

# 获取当前版本
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")

# 初始化失败列表
FAILED_BUILDS=()

# 遍历操作系统和架构组合
for GOOS in "${OS_LIST[@]}"; do
  for GOARCH in "${ARCH_LIST[@]}"; do
    # 排除不支持的组合
    if { [ "$GOOS" = "windows" ] && [ "$GOARCH" = "arm" ]; } || \
       { [ "$GOOS" = "darwin" ] && { [ "$GOARCH" = "386" ] || [ "$GOARCH" = "arm" ] || \
                                      [ "$GOARCH" = "mips" ] || [ "$GOARCH" = "mipsle" ] || \
                                      [ "$GOARCH" = "mips64" ] || [ "$GOARCH" = "mips64le" ]; }; } || \
       { [ "$GOOS" = "freebsd" ] && { [ "$GOARCH" = "mips" ] || [ "$GOARCH" = "mipsle" ] || \
                                        [ "$GOARCH" = "mips64" ] || [ "$GOARCH" = "mips64le" ]; }; }; then
      continue
    fi

    echo -e "Building for $GOOS/$GOARCH..."

    # 设置输出二进制文件名
    BINARY_NAME="komari-agent-${GOOS}-${GOARCH}"
    if [ "$GOOS" = "windows" ]; then
      BINARY_NAME="${BINARY_NAME}.exe"
    fi

    # 根据不同架构设置特定编译参数
    BUILD_ARGS="-trimpath -ldflags=-s -ldflags=-w -ldflags=-X -ldflags=github.com/komari-monitor/komari-agent/update.CurrentVersion=${VERSION}"
    
    # 为mipsle架构添加特定于mt7621芯片的参数
    if [ "$GOARCH" = "mipsle" ]; then
      echo -e "Adding specific flags for mt7621 MIPS architecture..."
      export GOMIPS=softfloat
    fi
    
    # 构建二进制文件
    env GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 go build $BUILD_ARGS -o "./build/$BINARY_NAME"

    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to build for $GOOS/$GOARCH${NC}"
      FAILED_BUILDS+=("$GOOS/$GOARCH")
    else
      echo -e "${GREEN}Successfully built $BINARY_NAME${NC}"
    fi
  done
done

# 输出失败的构建
if [ ${#FAILED_BUILDS[@]} -ne 0 ]; then
  echo -e "\n${RED}The following builds failed:${NC}"
  for BUILD in "${FAILED_BUILDS[@]}"; do
    echo -e "${RED}- $BUILD${NC}"
  done
else
  echo -e "\n${GREEN}All builds completed successfully.${NC}"
fi

# 提示构建完成
echo -e "\nBinaries are in the ./build directory."
