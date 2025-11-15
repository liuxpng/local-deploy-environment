#!/bin/bash

# ============================================
# Gitea 代码托管平台启动脚本
# ============================================

set -e

echo "=========================================="
echo "  Gitea 代码托管平台启动脚本"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
    echo -e "${RED}错误: .env 文件不存在${NC}"
    echo "请先复制并配置 .env 文件"
    exit 1
fi

# 检查关键配置是否已修改
source .env
if [ "$POSTGRES_PASSWORD" == "changeme456" ] || [ "$GITEA_ADMIN_PASSWORD" == "changeme123" ]; then
    echo -e "${YELLOW}警告: 检测到默认密码，强烈建议修改！${NC}"
    echo "请编辑 .env 文件，修改以下配置："
    echo "  - POSTGRES_PASSWORD"
    echo "  - GITEA_ADMIN_PASSWORD"
    echo "  - TRAEFIK_PASSWORD"
    echo ""
    read -p "是否继续启动？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}[1/4] 检查数据目录...${NC}"
mkdir -p data/gitea data/postgres data/traefik/logs
chmod 600 data/traefik/acme.json 2>/dev/null || touch data/traefik/acme.json && chmod 600 data/traefik/acme.json
echo "✓ 数据目录检查完成"
echo ""

echo -e "${GREEN}[2/4] 构建 Docker 镜像...${NC}"
docker-compose build
echo "✓ 镜像构建完成"
echo ""

echo -e "${GREEN}[3/4] 启动服务...${NC}"
docker-compose up -d
echo "✓ 服务启动完成"
echo ""

echo -e "${GREEN}[4/4] 等待服务就绪...${NC}"
echo "正在等待服务启动，这可能需要几分钟..."
sleep 10

# 检查服务状态
echo ""
echo "服务状态："
docker-compose ps
echo ""

echo "=========================================="
echo -e "${GREEN}  部署完成！${NC}"
echo "=========================================="
echo ""
echo "访问地址："
echo "  - Gitea:            http://${GITEA_DOMAIN:-git.localhost}"
echo "  - Traefik Dashboard: http://${TRAEFIK_DOMAIN:-traefik.localhost}"
echo ""
echo "默认账户（首次安装时设置）："
echo "  - 用户名: ${GITEA_ADMIN_USER:-gitadmin}"
echo "  - 密码:   ${GITEA_ADMIN_PASSWORD}"
echo ""
echo "SSH 克隆端口: ${GITEA_SSH_PORT:-2222}"
echo ""
echo "常用命令："
echo "  - 查看日志:   docker-compose logs -f"
echo "  - 停止服务:   docker-compose down"
echo "  - 重启服务:   docker-compose restart"
echo ""
echo -e "${YELLOW}注意: 首次访问 Gitea 需要完成安装向导${NC}"
echo "=========================================="
