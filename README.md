# Docker 镜像源切换脚本

该脚本用于在 Linux 系统上切换 Docker 镜像源为代理加速镜像，加速 Docker 镜像的下载和拉取。

## 功能

- 检查系统是否安装 Docker。
- 切换 Docker 镜像源为代理加速镜像。
- 备份原 Docker 配置文件。
- 自动重启 Docker 服务并应用新的镜像源配置。

## 系统要求

- Linux 操作系统（如 Ubuntu、CentOS、RHEL、Fedora 等）。
- 必须具有 root 权限。

## 使用方法

1. **一键安装**（推荐）

   你可以使用以下一键命令直接下载并运行脚本：

   ```bash
   bash <(curl -fsSL https://cdn.jsdelivr.net/gh/kiko923/DockerMirrorHelper@main/main.sh)


