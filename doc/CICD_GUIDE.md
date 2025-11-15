# Gitea CI/CD 和容器镜像仓库使用指南

本文档介绍如何使用 Gitea Actions（CI/CD）和 Gitea Container Registry（容器镜像仓库）。

## 目录

- [功能概述](#功能概述)
- [快速开始](#快速开始)
- [配置 Runner](#配置-runner)
- [使用 Gitea Actions](#使用-gitea-actions)
- [使用容器镜像仓库](#使用容器镜像仓库)
- [常见问题](#常见问题)

---

## 功能概述

### Gitea Actions（CI/CD）

- **GitHub Actions 兼容**：使用相同的 YAML 语法
- **20,000+ Actions**：可直接使用 GitHub Actions 生态
- **轻量级**：内置于 Gitea，无需额外服务
- **Docker 支持**：原生支持容器化构建

### Gitea Container Registry（镜像仓库）

- **Docker Registry v2 API**：完全兼容标准 Docker 工具
- **OCI 兼容**：支持 OCI 标准镜像
- **内置集成**：无需单独部署 Registry 或 Harbor
- **自动清理**：支持配置清理策略

---

## 快速开始

### 1. 启动服务

```bash
# 启动所有服务（包括 act_runner）
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看 act_runner 日志
docker-compose logs -f act_runner
```

### 2. 生成 Runner 注册令牌

1. 访问 Gitea：http://git.localhost
2. 使用管理员账户登录
3. 进入 **管理后台** → **Actions** → **Runners**
4. 点击 **"创建新的 Runner"**
5. 复制生成的注册令牌

### 3. 配置 Runner

将生成的令牌填入 `.env` 文件：

```bash
# 编辑 .env 文件
GITEA_RUNNER_REGISTRATION_TOKEN=你生成的令牌
```

重启 act_runner 服务：

```bash
docker-compose restart act_runner
```

### 4. 验证 Runner 状态

1. 返回 Gitea 管理后台 → Actions → Runners
2. 应该能看到 `default-runner` 已上线（绿色图标）
3. 状态显示为 **Idle**（空闲）

---

## 配置 Runner

### Runner 环境变量说明

在 [.env](.env) 文件中配置：

```bash
# 启用 Actions
GITEA_ACTIONS_ENABLED=true

# Runner 注册令牌（从 Gitea UI 生成）
GITEA_RUNNER_REGISTRATION_TOKEN=你的令牌

# Runner 名称
GITEA_RUNNER_NAME=default-runner

# Runner 标签（定义可用的执行环境）
# 格式: label:docker://image
GITEA_RUNNER_LABELS=ubuntu-latest:docker://catthehacker/ubuntu:act-latest
```

### 自定义 Runner 标签

可以添加多个标签，用逗号分隔：

```bash
GITEA_RUNNER_LABELS=ubuntu-latest:docker://catthehacker/ubuntu:act-latest,ubuntu-22.04:docker://catthehacker/ubuntu:runner-22.04
```

在 workflow 中使用：

```yaml
jobs:
  build:
    runs-on: ubuntu-22.04  # 使用自定义标签
```

---

## 使用 Gitea Actions

### 创建 Workflow

1. **在仓库中创建目录**：

   ```bash
   mkdir -p .gitea/workflows
   ```

2. **创建 workflow 文件**（例如 `.gitea/workflows/build.yml`）：

   ```yaml
   name: Build and Test

   on:
     push:
       branches:
         - main
     pull_request:
       branches:
         - main

   jobs:
     build:
       runs-on: ubuntu-latest
       container:
         image: catthehacker/ubuntu:act-latest

       steps:
         - name: Checkout code
           uses: actions/checkout@v3

         - name: Run build
           run: |
             echo "Building project..."
             # 添加你的构建命令

         - name: Run tests
           run: |
             echo "Running tests..."
             # 添加你的测试命令
   ```

3. **提交并推送**：

   ```bash
   git add .gitea/workflows/build.yml
   git commit -m "Add CI workflow"
   git push
   ```

4. **查看执行结果**：

   - 进入仓库页面
   - 点击 **Actions** 标签
   - 查看 workflow 运行状态

### 示例：构建 Docker 镜像

参考 [examples/workflow-build-and-push.yml](examples/workflow-build-and-push.yml)

**关键步骤**：

1. **配置 Secrets**（仓库设置 → Secrets）：

   - `DOCKER_USERNAME`：你的 Gitea 用户名
   - `DOCKER_TOKEN`：个人访问令牌（Settings → Applications → Generate Token）

2. **创建 workflow**：

   ```yaml
   name: Build and Push Image

   on:
     push:
       tags:
         - 'v*'

   jobs:
     docker:
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

         - name: Login to Registry
           uses: docker/login-action@v2
           with:
             registry: git.localhost:3000
             username: ${{ secrets.DOCKER_USERNAME }}
             password: ${{ secrets.DOCKER_TOKEN }}

         - name: Build and push
           uses: docker/build-push-action@v4
           with:
             context: .
             push: true
             tags: git.localhost:3000/${{ gitea.repository }}:${{ gitea.ref_name }}
   ```

---

## 使用容器镜像仓库

### 登录镜像仓库

```bash
# 方法1: 使用用户名和密码
docker login git.localhost:3000
# Username: your-username
# Password: your-password

# 方法2: 使用个人访问令牌（推荐）
docker login git.localhost:3000 -u your-username -p your-token
```

### 生成个人访问令牌

1. Gitea → 用户设置 → Applications
2. 点击 **"Generate New Token"**
3. 选择作用域：**API access**
4. 复制生成的令牌

### 推送镜像

```bash
# 1. 构建镜像
docker build -t git.localhost:3000/myorg/myapp:v1.0 .

# 2. 推送到 Gitea Registry
docker push git.localhost:3000/myorg/myapp:v1.0

# 3. 查看镜像
# Gitea → 用户/组织 → Packages → 找到你的镜像
```

### 拉取镜像

```bash
# 公开镜像（无需登录）
docker pull git.localhost:3000/myorg/myapp:v1.0

# 私有镜像（需要先登录）
docker login git.localhost:3000
docker pull git.localhost:3000/myorg/myapp:v1.0
```

### 镜像命名规范

```
{registry}/{owner}/{image}:{tag}

示例:
git.localhost:3000/myteam/backend:latest
git.localhost:3000/john/myapp:v1.2.3
```

- **registry**: Gitea 域名和端口（如 `git.localhost:3000`）
- **owner**: 用户名或组织名
- **image**: 镜像名称
- **tag**: 版本标签

### 配置镜像清理策略

1. 进入 Gitea → 用户/组织设置 → Packages
2. 选择要清理的镜像
3. 点击 **"Cleanup Rules"**
4. 配置清理规则：

   - **保留版本数**：例如保留最近 5 个版本
   - **保留天数**：删除超过 30 天的版本
   - **匹配模式**：使用正则表达式保留特定标签

示例规则：

```yaml
- 保留最近 5 个版本
- 删除超过 30 天的版本
- 保留所有 v* 标签（语义化版本）
```

---

## 常见问题

### Q1: Runner 无法注册

**问题**：act_runner 日志显示注册失败

**解决方案**：

1. 检查 `.env` 中的 `GITEA_RUNNER_REGISTRATION_TOKEN` 是否正确
2. 确认 Gitea 服务已完全启动
3. 查看 runner 日志：`docker-compose logs act_runner`
4. 重新生成注册令牌并更新 `.env`

### Q2: Workflow 无法访问私有镜像

**问题**：workflow 中拉取私有镜像失败

**解决方案**：

1. 在仓库中配置 Secrets（Settings → Secrets）
2. 添加 `DOCKER_USERNAME` 和 `DOCKER_TOKEN`
3. 在 workflow 中使用 `docker/login-action`

### Q3: 无法推送镜像到 Gitea Registry

**问题**：`docker push` 返回 401 或 404 错误

**解决方案**：

1. 确认已登录：`docker login git.localhost:3000`
2. 检查镜像命名是否正确（必须包含 registry 地址）
3. 确认用户/组织存在
4. 检查 Gitea 日志：`docker-compose logs gitea`

### Q4: HTTP registry 配置

**问题**：Docker 提示 "http: server gave HTTP response to HTTPS client"

**解决方案**（仅测试环境）：

编辑 `/etc/docker/daemon.json`：

```json
{
  "insecure-registries": ["git.localhost:3000"]
}
```

重启 Docker：

```bash
sudo systemctl restart docker
```

**生产环境**：请配置 HTTPS（参考 [README.md](README.md) 中的 HTTPS 配置）

### Q5: 镜像存储占用过大

**解决方案**：

1. 配置自动清理规则（见上文）
2. 手动删除不需要的镜像版本
3. 使用 `docker system prune` 清理 Docker 缓存
4. 监控 `gitea-data` 卷大小：`docker volume inspect gitea-data`

### Q6: Workflow 执行时间过长

**解决方案**：

1. 使用 Docker 层缓存：

   ```yaml
   - uses: docker/build-push-action@v4
     with:
       cache-from: type=registry,ref=...
       cache-to: type=registry,ref=...,mode=max
   ```

2. 减少构建层数，优化 Dockerfile
3. 使用更快的基础镜像
4. 考虑增加 runner 资源（CPU、内存）

---

## 最佳实践

### 1. 安全

- ✅ 使用个人访问令牌而非密码
- ✅ 定期轮换 Secrets 中的凭据
- ✅ 为不同项目使用不同的令牌
- ✅ 生产环境启用 HTTPS

### 2. 性能

- ✅ 使用 Docker 构建缓存
- ✅ 配置镜像清理策略
- ✅ 监控磁盘使用
- ✅ 使用轻量级基础镜像

### 3. 团队协作

- ✅ 使用组织管理项目
- ✅ 统一 workflow 命名规范
- ✅ 文档化 CI/CD 流程
- ✅ 定期review workflow 配置

---

## 参考资源

- [Gitea Actions 官方文档](https://docs.gitea.com/usage/actions/overview)
- [GitHub Actions 语法参考](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Gitea Package Registry](https://docs.gitea.com/usage/packages/overview)

---

## 相关文件

- [.env](.env) - 环境变量配置
- [docker-compose.yml](docker-compose.yml) - 服务编排
- [examples/workflow-build-and-push.yml](examples/workflow-build-and-push.yml) - Workflow 示例
- [README.md](README.md) - 项目主文档
