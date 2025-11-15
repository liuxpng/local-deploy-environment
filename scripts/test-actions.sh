#!/bin/bash

# ============================================
# Gitea Actions 快速测试脚本
# ============================================
# 此脚本帮助你快速验证 Gitea Actions 是否正常工作

set -e

echo "=========================================="
echo "Gitea Actions 验证脚本"
echo "=========================================="
echo ""

# 检查必要的命令
command -v git >/dev/null 2>&1 || { echo "错误: 需要安装 git"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "错误: 需要安装 curl"; exit 1; }

# 配置变量
GITEA_URL="http://git.localhost"
GITEA_API="${GITEA_URL}/api/v1"

echo "步骤 1: 检查 Gitea 服务是否可访问"
echo "----------------------------------------"
if curl -s -o /dev/null -w "%{http_code}" ${GITEA_URL} | grep -q "200\|302"; then
    echo "✅ Gitea 服务正常访问: ${GITEA_URL}"
else
    echo "❌ 无法访问 Gitea 服务，请确认服务已启动"
    exit 1
fi
echo ""

echo "步骤 2: 请提供 Gitea 访问令牌"
echo "----------------------------------------"
echo "如何获取令牌："
echo "1. 访问 ${GITEA_URL}"
echo "2. 登录你的账户"
echo "3. 进入 Settings → Applications"
echo "4. 生成新令牌 (Generate New Token)"
echo "5. 选择权限：All (all) 或 repository, write:repository"
echo ""
read -p "请输入你的 Gitea 访问令牌: " GITEA_TOKEN
echo ""

if [ -z "$GITEA_TOKEN" ]; then
    echo "❌ 令牌不能为空"
    exit 1
fi

echo "步骤 3: 验证令牌有效性"
echo "----------------------------------------"
USER_INFO=$(curl -s -H "Authorization: token ${GITEA_TOKEN}" ${GITEA_API}/user)
USERNAME=$(echo $USER_INFO | grep -o '"login":"[^"]*"' | cut -d'"' -f4)

if [ -z "$USERNAME" ]; then
    echo "❌ 令牌无效或权限不足"
    exit 1
fi

echo "✅ 令牌有效，用户名: ${USERNAME}"
echo ""

echo "步骤 4: 创建测试仓库"
echo "----------------------------------------"
REPO_NAME="test-actions-$(date +%s)"
CREATE_RESULT=$(curl -s -X POST \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${REPO_NAME}\",\"description\":\"Gitea Actions test repository\",\"private\":false,\"auto_init\":true}" \
    ${GITEA_API}/user/repos)

if echo $CREATE_RESULT | grep -q "\"name\":\"${REPO_NAME}\""; then
    echo "✅ 测试仓库创建成功: ${USERNAME}/${REPO_NAME}"
else
    echo "⚠️  仓库可能已存在或创建失败"
fi

REPO_URL="${GITEA_URL}/${USERNAME}/${REPO_NAME}.git"
echo "   仓库地址: ${REPO_URL}"
echo ""

echo "步骤 5: Clone 仓库并创建 workflow"
echo "----------------------------------------"
TEMP_DIR="/tmp/${REPO_NAME}"
rm -rf ${TEMP_DIR}

# Clone 仓库
git clone ${REPO_URL} ${TEMP_DIR} 2>&1 | grep -v "warning:"
cd ${TEMP_DIR}

# 创建 workflow 目录
mkdir -p .gitea/workflows

# 创建测试 workflow
cat > .gitea/workflows/test.yml << 'EOF'
name: Test Gitea Actions

on:
  push:
    branches:
      - main
      - master

jobs:
  hello-world:
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Print environment info
        run: |
          echo "=========================================="
          echo "Gitea Actions 测试成功！"
          echo "=========================================="
          echo "操作系统: $(uname -a)"
          echo "当前目录: $(pwd)"
          echo "用户: $(whoami)"
          echo "日期: $(date)"
          echo ""
          echo "✅ Gitea Actions 运行正常"
          echo "=========================================="

      - name: Test basic commands
        run: |
          echo "测试基本命令..."
          ls -la
          git --version
          echo "所有测试通过！"
EOF

echo "✅ Workflow 文件已创建"
echo ""

echo "步骤 6: 提交并推送 workflow"
echo "----------------------------------------"
git add .gitea/workflows/test.yml
git commit -m "Add test workflow for Gitea Actions"
git push origin main 2>&1 || git push origin master 2>&1

echo "✅ Workflow 已推送到仓库"
echo ""

echo "=========================================="
echo "验证步骤完成！"
echo "=========================================="
echo ""
echo "请执行以下步骤查看 Actions 执行结果："
echo ""
echo "1. 访问: ${GITEA_URL}/${USERNAME}/${REPO_NAME}"
echo "2. 点击顶部的 'Actions' 标签"
echo "3. 查看 'Test Gitea Actions' workflow 的执行状态"
echo ""
echo "预期结果："
echo "  ✅ Workflow 状态为绿色（成功）"
echo "  ✅ 可以看到 'Gitea Actions 测试成功！' 的输出"
echo ""
echo "如果 Actions 页面显示 workflow 正在运行或已完成，说明："
echo "  ✅ Gitea Actions 配置正确"
echo "  ✅ Runner 工作正常"
echo "  ✅ CI/CD 功能可以使用"
echo ""
echo "清理："
echo "  如果要删除测试仓库，可以在 Gitea UI 中操作："
echo "  仓库设置 → Danger Zone → Delete This Repository"
echo ""
