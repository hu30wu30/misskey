#!/bin/bash
set -e

# 仅适配 Ubuntu / Debian
if ! grep -E "Ubuntu|Debian" /etc/os-release &>/dev/null; then
    echo "❌ 此脚本仅支持 Ubuntu / Debian 系统，当前系统不兼容！"
    exit 1
fi

# 1. 检测root，非root自动切换sudo -i
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️ 当前不是root用户，自动切换root权限..."
    exec sudo -i bash "$0" "$@"
fi

# 2. 选择Github加速镜像站
echo "==================== Github下载站点选择 ===================="
echo "1) https://github.com (官方)"
echo "2) https://github.bibk.top"
echo "3) https://bgithub.xyz"
echo "4) https://gitclone.com"
echo "5) https://github.ur1.fun"
read -p "请输入数字选择下载站(1-5): " site_num
case $site_num in
    1) BASE_DL="https://github.com" ;;
    2) BASE_DL="https://github.bibk.top" ;;
    3) BASE_DL="https://bgithub.xyz" ;;
    4) BASE_DL="https://gitclone.com" ;;
    5) BASE_DL="https://github.ur1.fun" ;;
    *) echo "输入错误，默认使用官方github.com"; BASE_DL="https://github.com" ;;
esac
echo "✅ 当前选用下载源：$BASE_DL"

# 3. 检查并安装Docker
if ! command -v docker &>/dev/null; then
    echo "🔍 未检测到Docker，开始自动安装..."
    DOCKER_SCRIPT="${BASE_DL}/hu30wu30/misskey/blob/main/docker.sh"
    wget -O docker_install.sh "$DOCKER_SCRIPT"
    bash docker_install.sh
    rm -f docker_install.sh
fi

# 4. 检测解压工具(unzip)，无则询问安装
if ! command -v unzip &>/dev/null; then
    read -p "⚠️ 未检测到unzip解压工具，是否安装？(y/n): " unzip_ans
    if [[ "$unzip_ans" =~ ^[Yy]$ ]]; then
        apt update -y
        apt install unzip -y
    else
        echo "❌ 未安装解压工具，无法继续下载解压misskey，脚本退出"
        exit 1
    fi
fi

# 5. 设置安装路径，默认 /misskey
read -p "请输入Misskey安装路径，回车默认[/misskey]: " INSTALL_PATH
if [ -z "$INSTALL_PATH" ]; then
    INSTALL_PATH="/misskey"
fi
mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH" || exit 1
echo "📂 安装目录设置为：$INSTALL_PATH"

# 6. 下载 misskey.zip
ZIP_URL="${BASE_DL}/hu30wu30/misskey/blob/main/misskey.zip"
echo "📥 正在下载 Misskey 压缩包..."
wget -O misskey.zip "$ZIP_URL"
echo "📦 解压文件..."
unzip -o misskey.zip
rm -f misskey.zip

# 7. 输入域名（强制不能为空）
while true; do
    read -p "请输入你的站点域名（必填，例：misskey.example.com）: " DOMAIN
    if [ -n "$DOMAIN" ]; then
        break
    fi
    echo "❌ 域名不能为空，请重新输入！"
done

# 替换 default.yml 内的 example.com
CONFIG_FILE="./config/default.yml"
if [ -f "$CONFIG_FILE" ]; then
    sed -i "s|http://example.com|https://$DOMAIN|g" "$CONFIG_FILE"
    echo "✅ 域名已替换为 https://$DOMAIN"
else
    echo "⚠️ 未找到 $CONFIG_FILE 文件，跳过域名替换，请手动修改配置"
fi

# 8. 确认是否开始部署
read -p "是否开始执行Misskey完整安装流程？(y/n): " install_confirm
if [[ ! "$install_confirm" =~ ^[Yy]$ ]]; then
    echo "已取消安装，脚本结束"
    exit 0
fi

# 9. 执行安装命令
echo "==================== 开始部署 Misskey ===================="
apt update -y
apt install wget curl sudo vim git -y

# 一键swap脚本
wget https://raw.githubusercontent.com/zhucaidan/swap.sh/main/swap.sh && bash swap.sh

# 初始化与启动
docker compose run --rm web pnpm run init
docker compose up -d

echo "🎉 Misskey 部署命令执行完成！访问域名：https://$DOMAIN"
