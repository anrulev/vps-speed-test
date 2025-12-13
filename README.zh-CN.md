# VPS 速度测试工具

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows%20(WSL)-lightgrey)](https://github.com/anrulev/vps-speed-test)
[![Shell](https://img.shields.io/badge/shell-bash-green)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Tests](https://github.com/anrulev/vps-speed-test/workflows/Tests/badge.svg)](https://github.com/anrulev/vps-speed-test/actions)
[![ShellCheck](https://github.com/anrulev/vps-speed-test/workflows/ShellCheck/badge.svg)](https://github.com/anrulev/vps-speed-test/actions)
[![Maintenance](https://img.shields.io/badge/maintained-yes-brightgreen)](https://github.com/anrulev/vps-speed-test/commits/main)

**语言选择:** [🇷🇺 Русский](README.md) | [🇬🇧 English](README.en.md) | **🇨🇳 简体中文**

用于测试 VPS 服务器速度和连接质量的工具。

## 快速安装

一键安装命令：

```bash
curl -sSL https://raw.githubusercontent.com/anrulev/vps-speed-test/main/install.sh | bash
```

或使用 wget：

```bash
wget -qO- https://raw.githubusercontent.com/anrulev/vps-speed-test/main/install.sh | bash
```

安装脚本将自动：
- ✅ 检查依赖项
- ✅ 克隆仓库到 `~/vps-speed-test`
- ✅ 设置执行权限
- ✅ 提供添加到 PATH 的选项

## 项目结构

```
test_vps/
├── install.sh           # 自动安装脚本
├── test_vps_speed.sh    # 主测试脚本
├── view_reports.sh      # 查看和管理报告的脚本
├── servers.conf         # 服务器配置
├── reports/             # 测试报告目录
│   ├── report_2025-12-13_17-30-45.txt
│   └── report_2025-12-13_18-15-22.txt
├── README.md           # 文档 (RU)
├── README.en.md        # 文档 (EN)
└── README.zh-CN.md     # 文档 (CN)
```

## 安装

### 克隆仓库

```bash
git clone https://github.com/anrulev/vps-speed-test.git
cd vps-speed-test
chmod +x *.sh
```

### 系统要求

1. 确保已安装必要的工具：
   - `curl` - 用于获取地理位置
   - `ping` - 用于延迟测试
   - `traceroute` - 用于路由追踪
   - `bc` - 用于数学计算

2. （可选）安装 `jq` 以改进 JSON 解析：
   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt install jq

   # CentOS/RHEL
   sudo yum install jq
   ```

### 在 Windows 上运行

脚本无法在 Windows 上原生运行，但可以使用 **WSL**（适用于 Linux 的 Windows 子系统）：

1. **安装 WSL：**
   ```powershell
   # 以管理员身份运行 PowerShell
   wsl --install
   ```

2. **重启计算机**

3. **克隆并运行：**
   ```bash
   # 在 WSL 终端中
   git clone https://github.com/anrulev/vps-speed-test.git
   cd vps-speed-test
   chmod +x *.sh
   ./test_vps_speed.sh
   ```

**替代方案：** 使用 Git Bash（包含在 Git for Windows 中），但某些工具可能缺失。

## 配置

编辑 `servers.conf` 文件以添加/删除服务器：

```
# 格式：服务器名称|IP 地址
New York|192.3.81.8
Chicago, IL|198.23.228.15
My Custom Server|203.0.113.42
```

**规则：**
- 以 `#` 开头的行将被忽略（注释）
- 空行将被忽略
- 格式：`名称|IP`（竖线分隔符）
- IP 地址必须是有效的 IPv4 地址

## 使用方法

从任意目录运行脚本：

```bash
cd ~/test_vps
./test_vps_speed.sh
```

或使用完整路径：

```bash
~/test_vps/test_vps_speed.sh
```

## 测试参数

脚本会检查每个服务器的以下参数：

1. **Ping** - 响应延迟（最小/平均/最大/标准差）
2. **丢包率** - 丢失数据包的百分比
3. **抖动** - 连接稳定性（延迟变化）
4. **跳数** - 中间节点数量（traceroute）
5. **TCP 连接时间** - TCP 连接建立速度

## 评分公式

```
总分 = Ping + (丢包率 × 10) + (抖动 × 2)
```

分数越低，连接质量越好。

## 结果解读

### 连接质量：
- ★★★ **优秀**：ping < 50ms 且丢包率 < 1%
- ★★☆ **良好**：ping < 100ms 且丢包率 < 2%
- ★☆☆ **一般**：其他情况

### 奖牌：
- 🥇 - 最佳服务器
- 🥈 - 第二名
- 🥉 - 第三名

## 输出示例

```
========================================
  VPS 速度测试
========================================

获取您的位置信息...
您的 IP：198.45.195.56
您的位置：Moscow, Moscow, RU

已加载服务器：9

[测试每个服务器...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                最终结果
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#   位置           IP            Ping(ms) Loss% Jitter Hops TCP(ms) 分数
---------------------------------------------------------------------------
🥇 Amsterdam       23.94.101.88    60.96   0.0   3.52   11  64.72   68.00
🥈 Dublin          23.95.225.2     79.58   0.0   7.93   11  82.14   95.44
🥉 Chicago         198.23.228.15  143.86   0.0   3.25   11 156.62  150.36

🏆 推荐：Amsterdam
   平均 ping：60.96 ms | 丢包率：0.0% | 总分：68.00
```

## 执行时间

测试大约需要 **每台服务器 30-60 秒**，具体取决于：
- 配置中的服务器数量
- 您的互联网连接速度
- 服务器可用性

对于 9 台服务器：约 5-10 分钟

## 报告存储

每次测试运行都会**自动保存**到带有日期和时间的单独文件中：

```
reports/report_2025-12-13_17-30-45.txt
```

**文件名格式：** `report_YYYY-MM-DD_HH-MM-SS.txt`

**报告内容：**
- 测试日期和时间
- 系统信息
- 您的位置和 IP
- 每台服务器的详细结果
- 排名汇总表
- 最佳服务器推荐

**查看报告：**

使用交互式脚本管理报告：
```bash
cd ~/test_vps
./view_reports.sh
```

功能：
- 查看所有报告列表
- 查看最新报告
- 选择并查看特定报告
- 删除旧报告（>30 天）
- 删除所有报告

或通过命令行手动操作：
```bash
# 查看最新报告
cat ~/test_vps/reports/report_*.txt | tail -100

# 列出所有报告
ls -lht ~/test_vps/reports/

# 查看特定报告
cat ~/test_vps/reports/report_2025-12-13_17-30-45.txt
```

**比较报告：**
您可以比较不同时间的报告，以跟踪一天/一周内连接质量的变化。

## 故障排除

### 脚本找不到 servers.conf

确保 `servers.conf` 文件与脚本在同一目录中。

### traceroute 不工作

在 macOS 上，traceroute 可能需要 sudo。脚本将继续运行，跳数标记为"不可用"。

### 无法检测位置

检查您的互联网连接。脚本使用 ipinfo.io API 进行地理定位。

## 许可证

免费使用。
