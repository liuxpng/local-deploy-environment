# Gitea Secrets 配置指南

## 什么是 Secrets？

Secrets 是存储在 Gitea 中的加密敏感信息，用于在 Gitea Actions workflow 中安全地使用密码、令牌等敏感数据。

**特点**：
- ✅ 加密存储
- ✅ 不会在日志中显示
- ✅ 只能在 workflow 运行时访问
- ✅ 支持仓库级别和组织级别

---

## 设置 Secrets 的步骤

### 步骤 1: 生成个人访问令牌（用于 Docker Registry）

1. 访问 http://git.localhost
2. 登录你的账户
3. 点击右上角头像 → **Settings**
4. 左侧菜单 → **Applications**
5. 找到 **Generate New Token** 部分
6. 填写信息：
   - **Token Name**: `docker-registry-token`（或其他描述性名称）
   - **Select Permissions**: 选择 **All (all)** 或至少：
     - ✅ `repository` (读写仓库)
     - ✅ `package` (读写包/镜像)
7. 点击 **Generate Token**
8. **⚠️ 重要**: 立即复制令牌并保存，页面关闭后无法再次查看

---

### 步骤 2: 在仓库中添加 Secrets

#### 方法 A: Web UI 操作（推荐）

1. **进入仓库设置**
   - 访问你的仓库页面
   - 点击右上角 **Settings** 按钮

2. **找到 Secrets 页面**
   - 在左侧菜单中，找到 **Secrets** 或 **Actions** → **Secrets**
   - 点击进入

3. **添加第一个 Secret: DOCKER_USERNAME**
   - 点击 **Add Secret** 或 **New Secret**
   - Name: `DOCKER_USERNAME`
   - Value: 你的 Gitea 用户名（例如：`john`）
   - 点击 **Add Secret**

4. **添加第二个 Secret: DOCKER_TOKEN**
   - 再次点击 **Add Secret**
   - Name: `DOCKER_TOKEN`
   - Value: 粘贴步骤 1 生成的个人访问令牌
   - 点击 **Add Secret**

5. **验证**
   - 应该能在 Secrets 列表中看到：
     - `DOCKER_USERNAME`
     - `DOCKER_TOKEN`
   - ⚠️ 注意：Secret 的值不会显示，只显示名称

#### 方法 B: 使用 Gitea API

```bash
#!/bin/bash

# 配置变量
GITEA_URL="http://git.localhost"
GITEA_TOKEN="your-personal-access-token"  # 用于 API 认证的令牌
REPO_OWNER="your-username"
REPO_NAME="your-repo"

# 添加 DOCKER_USERNAME secret
curl -X PUT \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"data":"your-username"}' \
  "${GITEA_URL}/api/v1/repos/${REPO_OWNER}/${REPO_NAME}/actions/secrets/DOCKER_USERNAME"

# 添加 DOCKER_TOKEN secret
curl -X PUT \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"data":"ghp_your_token_here"}' \
  "${GITEA_URL}/api/v1/repos/${REPO_OWNER}/${REPO_NAME}/actions/secrets/DOCKER_TOKEN"
```

---

## 在 Workflow 中使用 Secrets

### 基本用法

使用 `${{ secrets.SECRET_NAME }}` 语法：

```yaml
name: Example Workflow

on: [push]

jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - name: Use secret
        run: echo "Using secret"
        env:
          MY_SECRET: ${{ secrets.DOCKER_TOKEN }}
```

### 完整示例: 构建并推送 Docker 镜像

创建 `.gitea/workflows/build-image.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - main
    tags:
      - 'v*'

env:
  REGISTRY: git.localhost:3000
  IMAGE_NAME: ${{ gitea.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    container:
      image: catthehacker/ubuntu:act-latest

    steps:
      # 1. 检出代码
      - name: Checkout
        uses: actions/checkout@v3

      # 2. 设置 Docker Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        with:
          config-inline: |
            [registry."git.localhost:3000"]
              http = true
              insecure = true

      # 3. 登录镜像仓库（使用 Secrets）
      - name: Login to Gitea Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      # 4. 提取元数据
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=tag
            type=raw,value=latest,enable=${{ gitea.ref == 'refs/heads/main' }}

      # 5. 构建并推送
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

---

## Secrets 命名规范

**推荐命名方式**：

- ✅ 全大写字母
- ✅ 使用下划线分隔单词
- ✅ 描述性名称

**示例**：

```yaml
DOCKER_USERNAME
DOCKER_TOKEN
API_KEY
DATABASE_PASSWORD
SSH_PRIVATE_KEY
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
SLACK_WEBHOOK_URL
```

**不推荐**：

```yaml
# ❌ 小写
docker_token

# ❌ 驼峰命名
dockerToken

# ❌ 不清晰
token1
secret
key
```

---

## 安全最佳实践

### 1. ✅ 使用最小权限原则

生成访问令牌时，只授予必要的权限：

```
# Docker Registry 需要的权限：
- repository (读写仓库)
- package (读写包)

# 不要选择：
- admin (管理员权限)
- delete (删除权限) - 除非必要
```

### 2. ✅ 定期轮换 Secrets

```bash
# 每 30-90 天更新一次敏感 Secrets
# 在 Gitea Settings → Applications 中：
1. 撤销旧令牌
2. 生成新令牌
3. 更新仓库中的 Secrets
```

### 3. ✅ 不要在代码或日志中打印 Secrets

```yaml
# ❌ 错误示例
- name: Debug
  run: echo "Token is ${{ secrets.DOCKER_TOKEN }}"

# ✅ 正确示例
- name: Use secret
  run: |
    # Secrets 会自动被 Gitea 隐藏在日志中
    docker login -u user -p "${{ secrets.DOCKER_TOKEN }}"
```

### 4. ✅ 为不同环境使用不同的 Secrets

```yaml
# 开发环境
DEV_API_KEY
DEV_DATABASE_URL

# 生产环境
PROD_API_KEY
PROD_DATABASE_URL
```

### 5. ✅ 使用组织级别 Secrets（如果团队使用）

对于团队共享的 Secrets（如公司 Docker Registry 凭据）：

1. 进入组织页面
2. Settings → Secrets
3. 添加组织级别的 Secrets
4. 所有该组织下的仓库都可以访问

---

## 常见问题

### Q1: Secret 的值在哪里可以看到？

**A**: 出于安全考虑，一旦添加 Secret，就无法再查看其值。只能：
- 更新（替换为新值）
- 删除

### Q2: Workflow 中使用 Secret 失败，显示为空？

**检查清单**：

1. ✅ Secret 名称是否正确（区分大小写）
   ```yaml
   # ❌ 错误
   ${{ secrets.docker_token }}

   # ✅ 正确
   ${{ secrets.DOCKER_TOKEN }}
   ```

2. ✅ Secret 是否已添加到仓库
   - 仓库 Settings → Secrets 中检查

3. ✅ Secret 是否在正确的作用域
   - 组织 Secret 需要仓库有访问权限

### Q3: 如何更新已有的 Secret？

1. 仓库 Settings → Secrets
2. 找到要更新的 Secret
3. 点击 **Edit** 或 **Update**
4. 输入新值
5. 保存

### Q4: 可以在 pull request 中使用 Secrets 吗？

**A**: 默认情况下：
- ✅ 来自同一仓库的 PR 可以使用 Secrets
- ⚠️ 来自 fork 的 PR **不能**使用 Secrets（安全限制）

如果需要在 fork PR 中使用，需要仓库维护者手动触发。

---

## 快速检查清单

使用 Secrets 前，确保：

- [ ] 已生成个人访问令牌
- [ ] 已在仓库 Settings → Secrets 中添加 Secret
- [ ] Secret 名称全大写，使用下划线分隔
- [ ] 在 workflow 中使用 `${{ secrets.NAME }}` 语法
- [ ] Workflow 文件已提交并推送
- [ ] 查看 Actions 日志确认 Secret 被正确使用（不会显示值）

---

## 相关资源

- [CICD_GUIDE.md](CICD_GUIDE.md) - CI/CD 完整使用指南
- [TEST_ACTIONS_MANUAL.md](TEST_ACTIONS_MANUAL.md) - Actions 手动测试指南
- [examples/workflow-build-and-push.yml](examples/workflow-build-and-push.yml) - 完整 workflow 示例
