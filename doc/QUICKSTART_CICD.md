# CI/CD 功能快速启动指南

本指南帮助你快速启动 Gitea Actions（CI/CD）和容器镜像仓库功能。

## 前提条件

- ✅ 已完成基础平台部署（Traefik + Gitea + PostgreSQL）
- ✅ Gitea 可以正常访问（http://git.localhost）
- ✅ 有管理员权限

## 部署步骤

### 步骤 1: 构建并启动服务

由于网络问题，如果无法拉取 `gitea/act_runner` 镜像，有以下选择：

#### 选项 A：使用代理或镜像加速器（推荐）

```bash
# 配置 Docker 镜像加速器（如果有）
# 编辑 /etc/docker/daemon.json

# 然后构建和启动
docker-compose build act_runner
docker-compose up -d
```

#### 选项 B：手动拉取镜像

```bash
# 使用其他网络环境拉取镜像
docker pull gitea/act_runner:latest

# 然后启动所有服务
docker-compose up -d
```

#### 选项 C：跳过 Runner，仅启用 Registry

如果暂时不需要 CI/CD，可以先启用容器镜像仓库：

```bash
# 编辑 docker-compose.yml，注释掉 act_runner 服务
# 或者只启动其他服务
docker-compose up -d traefik postgres gitea
```

Gitea 容器镜像仓库功能已内置，无需 runner 即可使用。

### 步骤 2: 验证 Gitea Actions 已启用

1. 访问 http://git.localhost
2. 登录管理员账户
3. 进入 **管理后台**（右上角头像 → Site Administration）
4. 左侧菜单找到 **Actions**
5. 确认显示 "Actions is enabled"

### 步骤 3: 生成 Runner 注册令牌

1. 在管理后台 → **Actions** → **Runners**
2. 点击 **"Create new Runner"** 按钮
3. 复制生成的注册令牌（格式类似：`d0f8a3b2...`）

### 步骤 4: 配置 Runner 令牌

编辑 `.env` 文件：

```bash
# 找到这一行
GITEA_RUNNER_REGISTRATION_TOKEN=

# 填入你复制的令牌
GITEA_RUNNER_REGISTRATION_TOKEN=d0f8a3b2...你的令牌
```

### 步骤 5: 启动 Runner

```bash
# 重启 act_runner 服务
docker-compose restart act_runner

# 查看 runner 日志
docker-compose logs -f act_runner
```

成功的日志应该显示：

```
INFO Runner registered successfully
INFO Runner started
```

### 步骤 6: 验证 Runner 状态

1. 返回 Gitea 管理后台 → Actions → Runners
2. 应该看到 `default-runner` 状态为 **Idle**（绿色图标）
3. 显示"Last online: Just now"

## 测试 CI/CD

### 创建测试仓库

1. 在 Gitea 创建新仓库（如 `test-actions`）
2. Clone 到本地：

   ```bash
   git clone http://git.localhost/your-username/test-actions.git
   cd test-actions
   ```

3. 创建 workflow：

   ```bash
   mkdir -p .gitea/workflows
   cat > .gitea/workflows/hello.yml << 'EOF'
   name: Hello World

   on:
     push:
       branches:
         - main

   jobs:
     hello:
       runs-on: ubuntu-latest
       container:
         image: catthehacker/ubuntu:act-latest

       steps:
         - name: Say hello
           run: echo "Hello from Gitea Actions!"
   EOF
   ```

4. 提交并推送：

   ```bash
   git add .gitea/workflows/hello.yml
   git commit -m "Add CI workflow"
   git push
   ```

5. 查看结果：
   - 在 Gitea 仓库页面点击 **Actions** 标签
   - 应该看到 workflow 正在运行或已完成
   - 点击查看详细日志

## 测试容器镜像仓库

### 1. 配置 Docker 允许 HTTP registry（仅测试环境）

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

### 2. 生成个人访问令牌

1. Gitea → 用户设置 → Applications
2. **Generate New Token**
3. Token Name: `docker-registry`
4. 选择作用域：**All（all）** 或 **API access**
5. 复制生成的令牌

### 3. 登录镜像仓库

```bash
docker login git.localhost:3000
# Username: your-username
# Password: 粘贴你的个人访问令牌
```

成功会显示：`Login Succeeded`

### 4. 推送测试镜像

```bash
# 拉取一个小镜像
docker pull alpine:latest

# 重新打标签
docker tag alpine:latest git.localhost:3000/your-username/test-image:v1.0

# 推送到 Gitea Registry
docker push git.localhost:3000/your-username/test-image:v1.0
```

### 5. 验证镜像

1. 在 Gitea 用户页面，点击 **Packages** 标签
2. 应该看到 `test-image` 镜像
3. 点击查看详细信息（版本、大小、创建时间等）

### 6. 拉取镜像测试

```bash
# 删除本地镜像
docker rmi git.localhost:3000/your-username/test-image:v1.0

# 重新拉取
docker pull git.localhost:3000/your-username/test-image:v1.0
```

## 故障排查

### Runner 无法注册

**症状**：日志显示 "Failed to register runner"

**解决**：

1. 检查 Gitea 是否已完全启动：`docker-compose ps`
2. 验证令牌是否正确：检查 `.env` 中的 `GITEA_RUNNER_REGISTRATION_TOKEN`
3. 重新生成令牌并更新 `.env`
4. 重启 runner：`docker-compose restart act_runner`

### Workflow 无法执行

**症状**：Actions 页面显示 workflow 但没有执行

**解决**：

1. 确认 Runner 状态为 **Idle**
2. 检查 workflow 语法是否正确
3. 查看 Gitea 日志：`docker-compose logs gitea`
4. 查看 Runner 日志：`docker-compose logs act_runner`

### 无法推送镜像

**症状**：`docker push` 失败，显示 401 或 404

**解决**：

1. 确认已登录：`docker login git.localhost:3000`
2. 检查镜像名称格式：`git.localhost:3000/owner/image:tag`
3. 确认 Packages 功能已启用：Gitea 管理后台 → Configuration → Packages
4. 查看 Gitea 日志：`docker-compose logs gitea | grep -i package`

### Docker 提示 "http: server gave HTTP response"

**解决**：

需要配置 Docker 允许 HTTP registry（见上文"配置 Docker"部分）

## 下一步

完成测试后，参考以下文档深入学习：

- **[CICD_GUIDE.md](CICD_GUIDE.md)** - 完整的 CI/CD 使用指南
- **[examples/workflow-build-and-push.yml](examples/workflow-build-and-push.yml)** - 构建镜像的 workflow 示例
- **[README.md](README.md)** - 平台主文档

## 常用命令

```bash
# 查看所有服务状态
docker-compose ps

# 查看特定服务日志
docker-compose logs -f gitea
docker-compose logs -f act_runner

# 重启服务
docker-compose restart gitea
docker-compose restart act_runner

# 停止所有服务
docker-compose down

# 启动所有服务
docker-compose up -d

# 查看存储卷使用情况
docker volume ls
docker system df
```

## 生产环境建议

在生产环境部署前，请务必：

1. ✅ 配置 HTTPS（Let's Encrypt）
2. ✅ 修改所有默认密码
3. ✅ 配置镜像清理策略
4. ✅ 设置存储卷备份
5. ✅ 监控磁盘使用
6. ✅ 限制 Runner 资源使用
7. ✅ 启用 Gitea 日志级别为 INFO

---

有问题？请查看 [CICD_GUIDE.md](CICD_GUIDE.md) 的常见问题部分。
