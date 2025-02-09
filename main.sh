#!/bin/bash

echo -e "\033[1;34m==== Docker 镜像源一键切换 ====\033[0m"

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

# 写入新配置（包含 dockerpull.cn 和 dockerpull.pw）
mkdir -p /etc/docker
cat > "$CONFIG_FILE" <<EOF
{
  "registry-mirrors": [
    "https://dockerpull.cn",
    "https://dockerpull.pw"
  ]
}
EOF

echo -e "\033[1;32m[✔] Docker 镜像源已成功替换为：\033[0m"
echo -e "\033[1;36m    ➜ https://dockerpull.cn\033[0m"
echo -e "\033[1;36m    ➜ https://dockerpull.pw\033[0m"

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
