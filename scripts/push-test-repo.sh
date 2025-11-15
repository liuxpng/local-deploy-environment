#!/bin/bash

# ============================================
# 推送测试仓库到 Gitea
# ============================================

set -e

echo "=========================================="
echo "推送测试仓库到 Gitea"
echo "=========================================="
echo ""

# 提示用户输入信息
read -p "请输入你的 Gitea 用户名: " USERNAME

if [ -z "$USERNAME" ]; then
    echo "❌ 用户名不能为空"
    exit 1
fi

GITEA_URL="http://git.localhost"
REPO_NAME="test-actions"
REPO_URL="${GITEA_URL}/${USERNAME}/${REPO_NAME}.git"

echo ""
echo "仓库信息:"
echo "  URL: ${REPO_URL}"
echo ""

# 切换到工作目录
cd /tmp/test-actions

echo "步骤 1: 配置 Git remote"
echo "----------------------------------------"

# 删除已存在的 remote（如果有）
git remote remove origin 2>/dev/null || true

# 添加新的 remote
git remote add origin ${REPO_URL}

echo "✅ Remote 已配置"
echo ""

echo "步骤 2: 确保分支名为 main"
echo "----------------------------------------"

# 获取当前分支名
CURRENT_BRANCH=$(git branch --show-current)
echo "当前分支: ${CURRENT_BRANCH}"

if [ "${CURRENT_BRANCH}" != "main" ]; then
    echo "重命名分支为 main..."
    git branch -M main
    echo "✅ 分支已重命名为 main"
else
    echo "✅ 分支已经是 main"
fi
echo ""

echo "步骤 3: 推送代码"
echo "----------------------------------------"
echo "推送到: ${REPO_URL}"
echo ""

# 推送代码
if git push -u origin main; then
    echo ""
    echo "=========================================="
    echo "✅ 推送成功！"
    echo "=========================================="
    echo ""
    echo "下一步:"
    echo "1. 访问仓库: ${GITEA_URL}/${USERNAME}/${REPO_NAME}"
    echo "2. 点击 'Actions' 标签"
    echo "3. 查看 'Test Gitea Actions' workflow 的执行状态"
    echo ""
    echo "预期结果:"
    echo "  ✅ 看到两个 jobs: 'Basic Test' 和 'Multiline Commands Test'"
    echo "  ✅ 状态为绿色（Success）或黄色（Running）"
    echo "  ✅ 可以点击查看详细日志"
    echo ""
else
    echo ""
    echo "❌ 推送失败"
    echo ""
    echo "可能的原因:"
    echo "1. 仓库尚未在 Gitea UI 中创建"
    echo "2. 用户名输入错误"
    echo "3. 需要认证（使用个人访问令牌）"
    echo ""
    echo "解决方案:"
    echo "1. 确认已在 Gitea UI 创建了 ${REPO_NAME} 仓库"
    echo "2. 如果需要认证，生成个人访问令牌:"
    echo "   Gitea → Settings → Applications → Generate New Token"
    echo "3. 使用令牌推送:"
    echo "   git push https://${USERNAME}:<token>@git.localhost/${USERNAME}/${REPO_NAME}.git main"
    exit 1
fi
