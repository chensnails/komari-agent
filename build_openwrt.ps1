# PowerShell脚本：为mt7621芯片的OpenWrt系统构建二进制文件

# 创建构建目录
if (-not (Test-Path -Path "./build" -PathType Container)) {
    New-Item -ItemType Directory -Path "./build"
    Write-Host "创建构建目录成功"
}

# 获取当前版本
try {
    $VERSION = git describe --tags --abbrev=0 2>$null
} catch {
    $VERSION = "dev"
}

if (-not $VERSION) {
    $VERSION = "dev"
}

# 为mt7621芯片的OpenWrt系统构建二进制文件
# mt7621通常使用mipsle架构
$env:GOOS = "linux"
$env:GOARCH = "mipsle"
$env:CGO_ENABLED = "0"

# 设置输出二进制文件名
$BINARY_NAME = "komari-agent-openwrt-mt7621"

# 构建二进制文件
Write-Host "正在为OpenWrt (mt7621) 构建二进制文件..."
try {
    go build -trimpath -ldflags="-s -w -X github.com/komari-monitor/komari-agent/update.CurrentVersion=${VERSION}" -o "./build/$BINARY_NAME"
    Write-Host "构建成功: $BINARY_NAME" -ForegroundColor Green
    
    Write-Host "\n二进制文件位置: ./build/"
    Write-Host "\n在OpenWrt (mt7621)上运行方法:"
    Write-Host "1. 将二进制文件复制到设备: scp ./build/$BINARY_NAME root@<您的路由器IP>:~/"
    Write-Host "2. SSH连接到路由器"
    Write-Host "3. 使二进制文件可执行: chmod +x ./$BINARY_NAME"
    Write-Host "4. 运行代理: ./$BINARY_NAME -e <api-endpoint> -t <api-token>"
} catch {
    Write-Host "构建失败，请检查Go环境是否正确安装。" -ForegroundColor Red
    Write-Host "错误信息: $_" -ForegroundColor Red
    exit 1
}