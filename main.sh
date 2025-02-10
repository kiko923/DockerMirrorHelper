#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
BLUE2='\033[1;36m'
PLAIN='\033[0m'

echo -e "${BLUE}==== Docker 镜像源一键切换 ====${PLAIN}"
# 检测并安装 jq
# 检测并静默安装 jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}[⏳] 未检测到 jq，正在安装...${PLAIN}"
    
    if command -v apt &> /dev/null; then
        apt update -qq && apt install -y -qq jq
    elif command -v yum &> /dev/null; then
        yum install -y -q jq
    elif command -v dnf &> /dev/null; then
        dnf install -y -q jq
    elif command -v pacman &> /dev/null; then
        pacman -Sy --noconfirm jq &> /dev/null
    elif command -v apk &> /dev/null; then
        apk add --no-cache jq > /dev/null 2>&1
    else
        echo -e "${RED}[错误] 无法自动安装 jq，程序继续运行。${PLAIN}"
    fi

    # 再次检查是否成功安装 jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[❌] jq 安装失败，程序继续运行。${PLAIN}"
    else
        echo -e "${GREEN}[✔] jq 安装成功！${PLAIN}"
    fi
fi


# 获取 IP 归属地（IPv4）
response=$(curl -s "https://www.bt.cn/api/panel/get_ip_info?ip=")
COUNTRY_CODE=$(echo "$response" | jq -r '.[].en_short_code' 2>/dev/null)

# 如果 IPv4 失败，则尝试 IPv6
if [[ -z "$COUNTRY_CODE" || "$COUNTRY_CODE" == "null" ]]; then
    COUNTRY_CODE=$(curl -s "https://[2606:4700:4700::1111]/cdn-cgi/trace" | grep 'loc=' | cut -d= -f2)
fi

# 如果仍然失败，则默认使用 "CN"
if [[ -z "$COUNTRY_CODE" || "$COUNTRY_CODE" == "null" ]]; then
    echo -e "${RED}[❌] 无法获取公网 IP，将默认使用 GitCode 镜像${PLAIN}"
    COUNTRY_CODE="CN"
    UNKNOW=1
else
    UNKNOW=0
fi

# 选择合适的 Docker 镜像源
if [[ "$COUNTRY_CODE" == "CN" ]]; then
    CONFIG_URL="https://raw.gitcode.com/yionchi/DockerMirrorHelper/raw/main/mirrors.json"
    echo -e "${YELLOW}[⏳] 识别到本机位于中国，使用 GitCode 镜像${PLAIN}"
elif [[ "$UNKNOW" -eq 1 ]]; then
    echo -e "${YELLOW}[⏳] 识别到本机位于未知 IP，默认使用 GitCode 镜像${PLAIN}"
    CONFIG_URL="https://raw.gitcode.com/yionchi/DockerMirrorHelper/raw/main/mirrors.json"
else
    CONFIG_URL="https://fastly.jsdelivr.net/gh/kiko923/DockerMirrorHelper@main/mirrors.json"
    echo -e "${YELLOW}[⏳] 识别到本机位于 ${COUNTRY_CODE}，使用 Fastly 镜像${PLAIN}"
fi

# 检测 Docker 是否安装并可用
if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    echo -e "${RED}[❌] 未检测到 Docker 或 Docker 运行异常，请先安装 Docker。${PLAIN}"
    exit 1
fi

echo -e "${GREEN}[✔] Docker 已安装，准备更换镜像源...${PLAIN}"

# 备份原有的 Docker 配置文件
CONFIG_FILE="/etc/docker/daemon.json"
BACKUP_FILE="/etc/docker/daemon.json.bak"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "${BLUE}[✔] 已备份原 Docker 配置文件到: $BACKUP_FILE${PLAIN}"
fi

# 下载远程镜像源配置
echo -e "${YELLOW}[⏳] 正在从远程仓库获取镜像源...${PLAIN}"
if command -v curl &> /dev/null; then
    MIRRORS_JSON=$(curl -fsSL "$CONFIG_URL")
elif command -v wget &> /dev/null; then
    MIRRORS_JSON=$(wget -qO- "$CONFIG_URL")
else
    echo -e "${RED}[❌] 未找到 curl 或 wget，请手动下载配置文件。${PLAIN}"
    exit 1
fi

# 检查是否成功获取到 JSON
if [[ -z "$MIRRORS_JSON" || "$MIRRORS_JSON" == "null" ]]; then
    echo -e "${RED}[❌] 无法获取远程配置文件，请检查网络或仓库地址。${PLAIN}"
    exit 1
fi

# 处理 JSON 写入
mkdir -p /etc/docker

if command -v jq &> /dev/null; then
    echo "$MIRRORS_JSON" | jq '.' > "$CONFIG_FILE"
else
    echo "$MIRRORS_JSON" > "$CONFIG_FILE"
fi

echo -e "${GREEN}[✔] Docker 镜像源已成功替换！${PLAIN}"
echo -e "${BLUE2}    配置文件内容：${PLAIN}"
echo "$MIRRORS_JSON" | jq .

# 输出正在重启 Docker
echo -e "${YELLOW}[⏳] 正在重启 Docker...${PLAIN}"

# 重新加载 Docker 配置并尝试重启服务
if systemctl list-units --type=service | grep -q docker; then
    systemctl daemon-reload
    systemctl restart docker
elif service --status-all 2>&1 | grep -q docker; then
    service docker restart
elif rc-service list | grep -q docker; then
    rc-service docker restart
else
    echo -e "${RED}[❌] 无法检测到合适的 Docker 服务管理工具，请手动重启 Docker。${PLAIN}"
    exit 1
fi

# 检查 Docker 状态
if systemctl is-active --quiet docker 2>/dev/null || service docker status 2>/dev/null | grep -q "running"; then
    echo -e "${GREEN}[✔] Docker 已成功重启，并使用新的镜像源！${PLAIN}"
else
    echo -e "${RED}[❌] Docker 重启失败，请检查日志并手动重启。${PLAIN}"
fi
