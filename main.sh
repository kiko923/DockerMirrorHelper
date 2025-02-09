#!/bin/bash

echo -e "\033[1;34m==== Docker 镜像源一键切换 ====\033[0m"

# 远程配置文件地址（你的配置文件地址）
CONFIG_URL="https://cdn.jsdelivr.net/gh/kiko923/DockerMirrorHelper@main/mirrors.json"

# 检测是否安装 Docker
if ! command -v docker &> /dev/null; then
    echo -e "\033[1;31m[错误] 未检测到 Docker，请先安装后再运行此脚本。\033[0m"
    exit 1
fi

echo -e "\033[1;32m[✔] Docker 已安装，准备更换镜像源...\033[0m"

# 备份原有的 Docker 配置文件
CONFIG_FILE="/etc/docker/daemon.json"
BACKUP_FILE="/etc/docker/daemon.json.bak"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "\033[1;34m[✔] 已备份原 Docker 配置文件到: $BACKUP_FILE\033[0m"
fi

# 下载远程镜像源配置
echo -e "\033[1;33m[⏳] 正在从远程仓库获取镜像源...\033[0m"
if command -v curl &> /dev/null; then
    MIRRORS_JSON=$(curl -fsSL "$CONFIG_URL")
elif command -v wget &> /dev/null; then
    MIRRORS_JSON=$(wget -qO- "$CONFIG_URL")
else
    echo -e "\033[1;31m[错误] 未找到 curl 或 wget，请手动下载配置文件。\033[0m"
    exit 1
fi

# 检查是否成功获取到 JSON
if [[ -z "$MIRRORS_JSON" ]]; then
    echo -e "\033[1;31m[错误] 无法获取远程配置文件，请检查网络或仓库地址。\033[0m"
    exit 1
fi

# 写入新的 Docker 配置
mkdir -p /etc/docker
echo "$MIRRORS_JSON" > "$CONFIG_FILE"

echo -e "\033[1;32m[✔] Docker 镜像源已成功替换！\033[0m"
echo -e "\033[1;36m    配置文件内容：\033[0m"
echo "$MIRRORS_JSON" | jq .

# 输出正在重启 Docker
echo -e "\033[1;33m[⏳] 正在重启 Docker...\033[0m"

# 重新加载 Docker 配置并尝试重启服务
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload
    systemctl restart docker
elif command -v service &> /dev/null; then
    service docker restart
elif command -v rc-service &> /dev/null; then
    rc-service docker restart
else
    echo -e "\033[1;31m[错误] 无法检测到合适的 Docker 服务管理工具，请手动重启 Docker。\033[0m"
    exit 1
fi

# 检查 Docker 状态
if systemctl is-active --quiet docker 2>/dev/null || service docker status 2>/dev/null | grep -q "running"; then
    echo -e "\033[1;32m[✔] Docker 已成功重启，并使用新的镜像源！\033[0m"
else
    echo -e "\033[1;31m[❌] Docker 重启失败，请检查日志并手动重启。\033[0m"
fi
