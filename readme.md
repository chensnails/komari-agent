# komari-agent

Komari Agent 是一个系统监控代理，能够收集系统信息并通过 WebSocket 与监控服务器通信。

## 安装说明

### 普通 Linux 系统

```bash
curl -fsSL https://raw.githubusercontent.com/komari-monitor/komari-agent/main/install.sh | bash -s -- --token YOUR_TOKEN --endpoint YOUR_ENDPOINT
```

### Windows 系统

使用 PowerShell 运行安装脚本：

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/komari-monitor/komari-agent/main/install.ps1 -OutFile install.ps1
.\install.ps1 -token YOUR_TOKEN -endpoint YOUR_ENDPOINT
```

## 针对 OpenWrt 系统（包括 mt7621 芯片设备）

Komari Agent 已特别适配 OpenWrt 系统，包括 mt7621 芯片设备。可以使用普通的 Linux 安装脚本，脚本会自动检测 OpenWrt 系统并进行相应配置：

```bash
curl -fsSL https://raw.githubusercontent.com/komari-monitor/komari-agent/main/install.sh | sh -s -- --token YOUR_TOKEN --endpoint YOUR_ENDPOINT
```

### OpenWrt 系统上的特殊优化

1. **系统识别**：自动检测 OpenWrt 系统和设备硬件
2. **网络接口处理**：正确监控 br-lan 等 OpenWrt 常用网络接口
3. **文件系统支持**：适配 squashfs、jffs2 和 overlay 等 OpenWrt 常用文件系统
4. **轻量级设计**：考虑嵌入式设备的资源限制，优化内存占用和 CPU 使用率

### OpenWrt 服务管理

安装后，可以使用以下命令管理服务：

```bash
# 查看服务状态
/etc/init.d/komari-agent status

# 启动服务
/etc/init.d/komari-agent start

# 停止服务
/etc/init.d/komari-agent stop

# 重启服务
/etc/init.d/komari-agent restart

# 禁用开机自启
/etc/init.d/komari-agent disable

# 启用开机自启
/etc/init.d/komari-agent enable
```

## 支持的系统和架构

Komari Agent 支持以下操作系统和架构：

### 操作系统
- Linux
- Windows
- Darwin (macOS)
- FreeBSD

### 处理器架构
- amd64
- arm64
- 386
- arm
- mips
- mipsle（特别针对 mt7621 芯片优化）
- mips64
- mips64le

## 配置选项

可以通过命令行参数配置 Komari Agent：

- `--token`：API 令牌（必需）
- `--endpoint`：API 端点（必需）
- `--interval`：数据收集间隔（秒）
- `--max-retries`：最大重试次数
- `--reconnect-interval`：重连间隔（秒）
- `--ignore-unsafe-cert`：忽略不安全的证书错误
- `--disable-auto-update`：禁用自动更新
- `--disable-web-ssh`：禁用远程控制（Web SSH 和 RCE）
- `--include-nics`：要包含的网络接口（逗号分隔）
- `--exclude-nics`：要排除的网络接口（逗号分隔）
- `--include-mountpoint`：要包含的挂载点（分号分隔）
- `--month-rotate`：网络统计月重置日期（0 为禁用）

## 卸载说明

### 普通 Linux 系统

```bash
# 停止并禁用服务
systemctl stop komari-agent
systemctl disable komari-agent
rm -f /etc/systemd/system/komari-agent.service
systemctl daemon-reload

# 删除安装目录
rm -rf /opt/komari
```

### OpenWrt 系统

```bash
# 停止并禁用服务
/etc/init.d/komari-agent stop
/etc/init.d/komari-agent disable
rm -f /etc/init.d/komari-agent

# 删除安装目录
rm -rf /opt/komari
```