#!/bin/bash

# ============================================
# 快速创建测试仓库和 Workflow
# ============================================

set -e

echo "=========================================="
echo "Gitea Actions 快速测试"
echo "=========================================="
echo ""

# 检查 git 是否安装
if ! command -v git &> /dev/null; then
    echo "❌ 错误: 需要安装 git"
    exit 1
fi

# 配置
GITEA_URL="http://git.localhost"
REPO_NAME="test-actions"

echo "步骤 1: 创建本地测试仓库"
echo "----------------------------------------"

# 创建临时目录
WORK_DIR="/tmp/${REPO_NAME}"
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

echo "✅ 工作目录: ${WORK_DIR}"
echo ""

echo "步骤 2: 初始化 Git 仓库"
echo "----------------------------------------"

git init
git config user.name "Test User"
git config user.email "test@example.com"

echo "✅ Git 仓库已初始化"
echo ""

echo "步骤 3: 创建 README 文件"
echo "----------------------------------------"

cat > README.md << 'EOF'
# Test Gitea Actions

这是一个用于测试 Gitea Actions 的示例仓库。

## Workflow 说明

此仓库包含一个简单的 CI/CD workflow，用于验证 Gitea Actions 是否正常工作。

## 功能验证

- ✅ Runner 自动执行
- ✅ 代码检出
- ✅ 基本命令执行
- ✅ 日志输出

推送代码到 main 分支后，Actions 会自动触发。
EOF

git add README.md
git commit -m "Initial commit: Add README"

echo "✅ README 文件已创建"
echo ""

echo "步骤 4: 创建 Gitea Actions Workflow"
echo "----------------------------------------"

mkdir -p .gitea/workflows

cat > .gitea/workflows/test.yml << 'EOF'
name: Test Gitea Actions

on:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master

jobs:
  test-basic:
    name: Basic Test
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      - name: 检出代码
        uses: actions/checkout@v3

      - name: 打印欢迎信息
        run: |
          echo "=========================================="
          echo "🎉 Gitea Actions 测试成功！"
          echo "=========================================="
          echo ""
          echo "📦 仓库信息:"
          echo "  仓库: ${{ gitea.repository }}"
          echo "  分支: ${{ gitea.ref }}"
          echo "  提交: ${{ gitea.sha }}"
          echo "  事件: ${{ gitea.event_name }}"
          echo ""
          echo "=========================================="

      - name: 系统信息
        run: |
          echo "操作系统信息:"
          uname -a
          echo ""
          echo "当前用户: $(whoami)"
          echo "当前目录: $(pwd)"
          echo ""
          echo "磁盘使用:"
          df -h /
          echo ""
          echo "内存使用:"
          free -h

      - name: 检查仓库内容
        run: |
          echo "仓库文件列表:"
          ls -lah
          echo ""
          echo "Git 状态:"
          git status
          echo ""
          echo "最近的提交:"
          git log --oneline -5

      - name: 测试基本命令
        run: |
          echo "测试常用命令..."
          echo ""

          # Git
          echo "✅ Git 版本: $(git --version)"

          # 基本工具
          echo "✅ Bash 版本: $BASH_VERSION"
          echo "✅ 工作目录: $(pwd)"

          # 环境变量
          echo ""
          echo "Gitea 环境变量:"
          env | grep GITEA || echo "无 Gitea 特定环境变量"

          echo ""
          echo "=========================================="
          echo "✅ 所有测试通过！"
          echo "=========================================="

  test-multiline:
    name: Multiline Commands Test
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      - name: 多行脚本测试
        run: |
          echo "测试多行脚本执行..."

          for i in {1..5}; do
            echo "  循环 $i"
          done

          echo ""
          echo "✅ 多行脚本执行成功"

      - name: 条件测试
        run: |
          if [ -f "README.md" ]; then
            echo "✅ README.md 存在"
          else
            echo "❌ README.md 不存在"
            exit 1
          fi
EOF

git add .gitea/workflows/test.yml
git commit -m "Add Gitea Actions workflow"

echo "✅ Workflow 文件已创建"
echo ""

echo "步骤 5: 创建示例 Dockerfile（可选）"
echo "----------------------------------------"

cat > Dockerfile << 'EOF'
FROM alpine:latest

RUN apk add --no-cache bash curl

COPY README.md /app/

WORKDIR /app

CMD ["cat", "README.md"]
EOF

git add Dockerfile
git commit -m "Add example Dockerfile"

echo "✅ Dockerfile 已创建"
echo ""

echo "=========================================="
echo "准备完成！"
echo "=========================================="
echo ""
echo "接下来的步骤:"
echo ""
echo "1. 在 Gitea UI 中创建新仓库:"
echo "   - 访问: ${GITEA_URL}"
echo "   - 点击右上角 '+' → 'New Repository'"
echo "   - 仓库名: ${REPO_NAME}"
echo "   - ❌ 不要勾选 'Initialize Repository'"
echo "   - 点击 'Create Repository'"
echo ""
echo "2. 复制仓库 URL（类似: ${GITEA_URL}/your-username/${REPO_NAME}.git）"
echo ""
echo "3. 推送代码到 Gitea:"
echo ""
echo "   cd ${WORK_DIR}"
echo "   git remote add origin ${GITEA_URL}/your-username/${REPO_NAME}.git"
echo "   git push -u origin main"
echo ""
echo "4. 查看 Actions 执行:"
echo "   - 访问仓库页面"
echo "   - 点击 'Actions' 标签"
echo "   - 查看 'Test Gitea Actions' workflow 的执行状态"
echo ""
echo "=========================================="
echo ""
echo "💡 提示: 如果推送到 main 分支失败，可能是默认分支名为 master，使用："
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "工作目录: ${WORK_DIR}"
echo "所有文件已准备就绪！"
echo ""
