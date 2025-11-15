# Gitea Actions 手动验证指南

## 快速验证步骤

### 步骤 1: 登录 Gitea 并检查 Runner 状态

1. 访问 http://git.localhost
2. 登录你的账户
3. 点击右上角头像 → **Site Administration**（管理后台）
4. 左侧菜单点击 **Actions** → **Runners**

**预期结果**：

- ✅ 看到 `default-runner` 在列表中
- ✅ 状态显示为 **Idle**（绿色）
- ✅ 标签显示 `ubuntu-latest`

如果看不到 runner 或状态不对，检查：

```bash
# 查看 runner 日志
docker-compose logs act_runner

# 应该看到：
# level=info msg="Runner registered successfully."
# level=info msg="Starting runner daemon"
```

---

### 步骤 2: 创建测试仓库

1. 在 Gitea 首页，点击右上角 **+** → **New Repository**
2. 填写信息：
   - Repository Name: `test-actions`
   - Description: `Test Gitea Actions`
   - ✅ 勾选 **Initialize Repository** (README)
3. 点击 **Create Repository**

---

### 步骤 3: 添加 Workflow 文件

#### 方法 A：通过 Gitea Web UI（最简单）

1. 在仓库页面，点击 **New File** 按钮
2. 文件路径输入：`.gitea/workflows/test.yml`
3. 粘贴以下内容：

```yaml
name: Hello Gitea Actions

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Say Hello
        run: |
          echo "=========================================="
          echo "✅ Gitea Actions 工作正常！"
          echo "=========================================="
          echo "仓库: ${{ gitea.repository }}"
          echo "分支: ${{ gitea.ref }}"
          echo "提交: ${{ gitea.sha }}"
          echo "=========================================="

      - name: System Info
        run: |
          echo "操作系统: $(uname -a)"
          echo "当前用户: $(whoami)"
          echo "当前目录: $(pwd)"
          ls -la
```

4. 填写 Commit Message: `Add test workflow`
5. 点击 **Commit Changes**

#### 方法 B：通过 Git 命令行

```bash
# 1. Clone 仓库
git clone http://git.localhost/your-username/test-actions.git
cd test-actions

# 2. 创建 workflow 目录
mkdir -p .gitea/workflows

# 3. 创建 workflow 文件
cat > .gitea/workflows/test.yml << 'EOF'
name: Hello Gitea Actions

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Say Hello
        run: |
          echo "=========================================="
          echo "✅ Gitea Actions 工作正常！"
          echo "=========================================="
          echo "仓库: ${{ gitea.repository }}"
          echo "分支: ${{ gitea.ref }}"
          echo "提交: ${{ gitea.sha }}"
          echo "=========================================="

      - name: System Info
        run: |
          echo "操作系统: $(uname -a)"
          echo "当前用户: $(whoami)"
          echo "当前目录: $(pwd)"
          ls -la
EOF

# 4. 提交并推送
git add .gitea/workflows/test.yml
git commit -m "Add test workflow"
git push
```

---

### 步骤 4: 查看 Actions 执行结果

1. 在仓库页面，点击顶部的 **Actions** 标签
2. 应该能看到 workflow 运行记录

**预期结果**：

- ✅ 看到 "Hello Gitea Actions" workflow
- ✅ 状态为 🟢 **Success**（绿色对勾）或 🟡 **Running**（黄色圆圈）
- ✅ 点击可以查看详细日志

3. 点击 workflow 名称 → 点击 job 名称 `test`
4. 展开每个步骤查看输出日志

**应该看到的输出**：

```
==========================================
✅ Gitea Actions 工作正常！
==========================================
仓库: your-username/test-actions
分支: refs/heads/main
提交: abc123...
==========================================
```

---

## 验证结果判断

### ✅ 成功标志

如果看到以下情况，说明 Gitea Actions 完全正常：

1. ✅ Runner 在管理后台显示 **Idle** 状态
2. ✅ Workflow 自动触发（推送代码后）
3. ✅ Workflow 状态变为 **Success**（绿色）
4. ✅ 可以查看详细的执行日志
5. ✅ 日志中显示 "Gitea Actions 工作正常！"

### ❌ 可能的问题

#### 问题1: Actions 标签不显示

**原因**: Actions 功能未启用

**解决**:
```bash
# 检查环境变量
docker-compose exec gitea env | grep GITEA__actions__ENABLED

# 应该返回: GITEA__actions__ENABLED=true
```

#### 问题2: Workflow 不执行

**可能原因**:
- Runner 未注册或离线
- Workflow 文件路径错误（必须是 `.gitea/workflows/*.yml`）
- YAML 语法错误

**解决**:
```bash
# 查看 runner 状态
docker-compose logs act_runner

# 查看 gitea 日志
docker-compose logs gitea | grep -i action
```

#### 问题3: Workflow 一直处于 "Waiting" 状态

**原因**: 没有可用的 runner 或 runner 标签不匹配

**解决**:
- 检查 workflow 中的 `runs-on: ubuntu-latest` 与 runner 标签是否匹配
- 确认 runner 状态为 **Idle**

---

## 进阶测试：构建 Docker 镜像

一切正常后，可以测试完整的 CI/CD 流程：

### 1. 创建 Dockerfile

在仓库根目录创建 `Dockerfile`:

```dockerfile
FROM alpine:latest
RUN echo "Hello from Docker image built by Gitea Actions"
CMD ["echo", "Image works!"]
```

### 2. 创建构建 workflow

创建 `.gitea/workflows/build-image.yml`:

```yaml
name: Build Docker Image

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        with:
          config-inline: |
            [registry."git.localhost:3000"]
              http = true
              insecure = true

      - name: Login to Gitea Registry
        uses: docker/login-action@v2
        with:
          registry: git.localhost:3000
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Build and Push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: git.localhost:3000/${{ gitea.repository }}:${{ gitea.ref_name }}
```

### 3. 配置 Secrets

1. 在仓库页面，进入 **Settings** → **Secrets**
2. 添加两个 secrets:
   - `DOCKER_USERNAME`: 你的 Gitea 用户名
   - `DOCKER_TOKEN`: 个人访问令牌（Settings → Applications → Generate Token）

### 4. 创建 Tag 触发构建

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 5. 验证镜像

构建成功后：

1. Gitea → 用户页面 → **Packages** 标签
2. 应该能看到构建的镜像
3. 可以拉取测试：

```bash
docker pull git.localhost:3000/your-username/test-actions:v1.0.0
docker run git.localhost:3000/your-username/test-actions:v1.0.0
```

---

## 总结

完成以上步骤后，你已经验证了：

- ✅ Gitea Actions 基本功能
- ✅ Runner 正常工作
- ✅ Workflow 可以正常执行
- ✅ 可以查看日志和状态
- ✅ （可选）可以构建和推送 Docker 镜像

现在可以开始在实际项目中使用 Gitea Actions 了！

---

**相关文档**:
- [CICD_GUIDE.md](CICD_GUIDE.md) - 完整 CI/CD 使用指南
- [examples/workflow-build-and-push.yml](examples/workflow-build-and-push.yml) - 更多 workflow 示例
