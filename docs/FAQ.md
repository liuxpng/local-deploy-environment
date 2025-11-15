# 常见问题解答 (FAQ)

本文档整理了在部署和使用企业级代码托管平台过程中的常见问题及解决方案。

---

## 📑 目录

- [部署与配置](#部署与配置)
- [访问与连接](#访问与连接)
- [CI/CD 相关](#cicd-相关)
- [镜像仓库相关](#镜像仓库相关)
- [Secrets 管理](#secrets-管理)
- [性能优化](#性能优化)
- [数据管理](#数据管理)

---

## 部署与配置

### Q: 服务启动失败怎么办?

**症状**: `docker-compose up -d` 后服务无法正常启动

**解决方案**:

```bash
# 1. 查看详细日志
docker-compose logs

# 2. 检查端口占用
sudo netstat -tlnp | grep -E '(80|443|2222|3000|5432)'

# 3. 检查服务状态
docker-compose ps

# 4. 清理并重启
docker-compose down
docker-compose up -d
```

**常见原因**:
- 端口被占用（80, 443, 2222等）
- Docker 服务未启动
- 配置文件格式错误
- 磁盘空间不足

---

### Q: 修改 .env 文件后如何使配置生效?

**重要**: 修改 `.env` 文件中的环境变量后,**必须重建容器**才能生效,仅重启容器是不够的！

**正确做法**:

```bash
# 1. 修改 .env 文件
nano .env

# 2. 停止服务
docker-compose down

# 3. 重建并启动容器（这会使用新的环境变量）
docker-compose up -d --force-recreate

# 或者分步骤:
docker-compose build
docker-compose up -d
```

**错误做法**（不会生效）:

```bash
# ❌ 仅重启容器 - 环境变量不会更新
docker-compose restart

# ❌ 只是 down 和 up - 使用已存在的容器
docker-compose down
docker-compose up -d  # 这样不会重建容器
```

**为什么**:
- 环境变量在容器创建时注入
- `restart` 只是重启进程,不重建容器
- `up -d` 默认使用已存在的容器
- 必须用 `--force-recreate` 强制重建容器

**验证环境变量是否生效**:

```bash
# 检查容器中的环境变量
docker-compose exec gitea env | grep GITEA_ADMIN

# 应该看到新的配置值
```

---

### Q: 如何修改默认密码?

**Gitea 管理员密码**:

在首次访问 Gitea 时,通过安装向导设置管理员密码。

**Traefik Dashboard 密码**:

查看 [如何修改 Traefik Dashboard 密码](#q-如何修改-traefik-dashboard-密码)

**数据库密码**:

修改 `.env` 文件中的 `POSTGRES_PASSWORD`,然后重建容器:

```bash
docker-compose down
docker-compose up -d --force-recreate postgres
```

---

### Q: 忘记 Gitea 管理员密码怎么办?

**解决方案**:

```bash
# 进入 Gitea 容器重置密码
docker-compose exec gitea gitea admin user change-password \
  --username gitadmin \
  --password 新密码
```

**替代方案**（创建新管理员）:

```bash
docker-compose exec gitea gitea admin user create \
  --username newadmin \
  --password 新密码 \
  --email admin@example.com \
  --admin
```

---

### Q: 如何修改 Traefik Dashboard 密码?

**推荐方法**: 使用 Docker 容器生成密码哈希

```bash
# 1. 生成密码哈希（替换 your-new-password）
docker run --rm httpd:2.4-alpine htpasswd -nbB admin your-new-password

# 2. 输出示例:
# admin:$2y$05$xyz...

# 3. 复制整个输出,编辑 traefik/dynamic/dashboard.yml
# 将 users 下的内容替换为上面的输出

# 4. 重启 Traefik
docker-compose restart traefik
```

**备选方法**: 使用在线工具

访问 https://hostingcanada.org/htpasswd-generator/
- 用户名: admin
- 密码: 你的新密码
- 加密方式: bcrypt

**常见问题**:

- **Q**: 修改后仍然提示密码错误?
  - **A**: 确保复制完整的哈希值,包括 `$2y$05$...` 整个字符串
  - 检查 YAML 格式缩进是否正确
  - 重启 Traefik: `docker-compose restart traefik`

- **Q**: 不提示输入密码?
  - **A**: 清除浏览器缓存和 cookies
  - 使用无痕/隐私模式访问

- **Q**: 生成的哈希无效?
  - **A**: 确保使用 bcrypt 加密方式
  - 使用 Docker 方法最可靠

---

## 访问与连接

### Q: 无法访问 Gitea 怎么办?

**检查清单**:

```bash
# 1. 检查服务是否运行
docker-compose ps

# 2. 检查 Gitea 日志
docker-compose logs gitea

# 3. 检查 Traefik 路由
docker-compose logs traefik | grep gitea

# 4. 检查防火墙
sudo ufw status

# 5. 检查 hosts 文件配置（本地部署）
cat /etc/hosts | grep git.localhost
```

**本地部署添加 hosts**:

```bash
# Linux/Mac
sudo nano /etc/hosts
# 添加:
127.0.0.1 git.localhost traefik.localhost

# Windows (管理员权限)
# 编辑 C:\Windows\System32\drivers\etc\hosts
# 添加:
127.0.0.1 git.localhost traefik.localhost
```

---

### Q: 如何配置域名?

**步骤**:

1. **修改 `.env` 文件**:
   ```bash
   DOMAIN=yourdomain.com
   GITEA_DOMAIN=git.yourdomain.com
   TRAEFIK_DOMAIN=traefik.yourdomain.com
   ```

2. **配置 DNS 记录**:
   - `git.yourdomain.com` → 服务器 IP
   - `traefik.yourdomain.com` → 服务器 IP

3. **启用 HTTPS**（生产环境必须）:
   - 修改 `.env` 中的 `ACME_EMAIL`
   - 按照 [README.md](../README.md) 中的 HTTPS 配置说明操作

4. **重启服务**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

---

### Q: SSH 克隆失败怎么办?

**症状**: `git clone ssh://git@git.localhost:2222/user/repo.git` 失败

**解决方案**:

```bash
# 1. 检查 SSH 端口是否开放
nc -zv localhost 2222

# 2. 检查 Gitea SSH 服务
docker-compose exec gitea netstat -tlnp | grep 22

# 3. 检查 SSH 密钥是否已添加到 Gitea
# Gitea → Settings → SSH / GPG Keys

# 4. 使用 HTTPS 作为备选
git clone http://git.localhost/user/repo.git
```

---

## CI/CD 相关

### Q: Runner 无法注册怎么办?

**症状**: act_runner 日志显示 "token is empty" 或注册失败

**解决方案**:

```bash
# 1. 检查注册令牌是否正确
cat .env | grep GITEA_RUNNER_REGISTRATION_TOKEN

# 2. 查看 Runner 日志
docker-compose logs act_runner

# 3. 确认 Gitea 服务已完全启动
docker-compose logs gitea | grep "Listen:"

# 4. 重新生成注册令牌
# Gitea → Site Administration → Actions → Runners → Create

# 5. 更新 .env 文件

# 6. 重新创建 Runner 容器
docker-compose stop act_runner
docker-compose rm -f act_runner
docker-compose up -d act_runner
```

---

### Q: Actions 标签不显示怎么办?

**症状**: Gitea 仓库页面没有 Actions 标签

**解决方案**:

```bash
# 1. 检查 Actions 功能是否启用
docker-compose exec gitea env | grep GITEA__actions__ENABLED

# 应该返回: GITEA__actions__ENABLED=true

# 2. 如果未启用,检查 docker-compose.yml
# 确保包含:
# - GITEA__actions__ENABLED=true

# 3. 重启 Gitea
docker-compose restart gitea
```

---

### Q: Workflow 一直处于 Waiting 状态?

**症状**: Workflow 提交后一直显示黄色 "Waiting" 状态

**原因**: 没有可用的 Runner 或 Runner 标签不匹配

**解决方案**:

```bash
# 1. 检查 Runner 状态
# Gitea → Site Administration → Actions → Runners
# 确认 Runner 状态为 "Idle"（绿色）

# 2. 检查 Runner 标签
# 确认 workflow 中的 runs-on 与 Runner 标签匹配
# 例如: runs-on: ubuntu-latest

# 3. 查看 Runner 日志
docker-compose logs act_runner

# 4. 重启 Runner
docker-compose restart act_runner
```

---

### Q: Workflow 不执行怎么办?

**症状**: 推送代码后 Workflow 没有触发

**检查清单**:

1. **检查 Workflow 文件路径**:
   ```
   ✅ 正确: .gitea/workflows/xxx.yml
   ❌ 错误: .github/workflows/xxx.yml
   ❌ 错误: .gitea/workflow/xxx.yml (少了s)
   ```

2. **检查 YAML 语法**:
   ```bash
   # 使用在线工具验证: https://www.yamllint.com/
   ```

3. **检查触发条件**:
   ```yaml
   on:
     push:
       branches:
         - main  # 确保分支名称正确
   ```

4. **查看 Gitea Actions 日志**:
   ```bash
   docker-compose logs gitea | grep -i action
   ```

---

### Q: Workflow 无法访问私有镜像?

**症状**: Workflow 中拉取私有 Docker 镜像失败

**解决方案**:

1. **配置 Repository Secrets**:
   - Gitea → 仓库 → Settings → Secrets → Add Secret
   - 添加 `DOCKER_USERNAME` 和 `DOCKER_TOKEN`

2. **在 Workflow 中登录**:
   ```yaml
   steps:
     - name: Login to Docker Registry
       uses: docker/login-action@v2
       with:
         registry: git.localhost:3000
         username: ${{ secrets.DOCKER_USERNAME }}
         password: ${{ secrets.DOCKER_TOKEN }}
   ```

详细说明见 [SECRETS_GUIDE.md](SECRETS_GUIDE.md)

---

## 镜像仓库相关

### Q: 无法推送镜像到 Gitea Registry?

**症状**: `docker push` 返回 401, 403 或 404 错误

**解决方案**:

```bash
# 1. 确认已登录 Registry
docker login git.localhost:3000
# 输入 Gitea 用户名和密码（或个人访问令牌）

# 2. 检查镜像命名格式
# ✅ 正确格式:
docker tag myimage:latest git.localhost:3000/username/myimage:latest

# ❌ 错误格式（缺少 registry 地址）:
docker tag myimage:latest username/myimage:latest

# 3. 确认用户/组织存在
# 镜像路径中的 username 必须是 Gitea 中存在的用户或组织

# 4. 推送镜像
docker push git.localhost:3000/username/myimage:latest

# 5. 查看 Gitea 日志
docker-compose logs gitea | grep -i registry
```

---

### Q: Docker 提示 HTTP 响应错误?

**症状**: "http: server gave HTTP response to HTTPS client"

**原因**: Docker 默认要求 HTTPS,但测试环境使用 HTTP

**解决方案（仅测试环境）**:

```bash
# 1. 编辑 Docker 配置
sudo nano /etc/docker/daemon.json

# 2. 添加 insecure-registries
{
  "insecure-registries": ["git.localhost:3000"]
}

# 3. 重启 Docker
sudo systemctl restart docker

# 4. 重启项目容器
docker-compose down
docker-compose up -d
```

**生产环境**:
- 必须配置 HTTPS
- 使用有效的 SSL 证书
- 参考 [README.md](../README.md) 的 HTTPS 配置章节

---

### Q: 镜像存储占用过大怎么办?

**解决方案**:

1. **手动清理不需要的镜像**:
   - Gitea → 用户/组织 → Packages
   - 选择不需要的镜像版本 → Delete

2. **清理 Docker 缓存**:
   ```bash
   # 清理未使用的镜像
   docker image prune -a

   # 清理所有未使用的资源
   docker system prune -a --volumes
   ```

3. **监控存储使用**:
   ```bash
   # 查看数据卷大小
   docker volume inspect gitea-data

   # 查看 Docker 整体使用情况
   docker system df
   ```

4. **配置镜像清理策略** (计划中的功能):
   - 自动删除旧版本镜像
   - 设置存储配额

---

### Q: 如何配置镜像清理策略?

**当前状态**: Gitea 的镜像自动清理功能正在开发中

**临时方案**: 使用定时任务手动清理

```bash
# 创建清理脚本
cat > ~/cleanup-old-images.sh << 'EOF'
#!/bin/bash
# 清理7天前的镜像（示例）
docker image prune -a --filter "until=168h"
EOF

chmod +x ~/cleanup-old-images.sh

# 添加到 crontab（每周执行一次）
(crontab -l 2>/dev/null; echo "0 2 * * 0 ~/cleanup-old-images.sh") | crontab -
```

---

## Secrets 管理

### Q: Secret 的值在哪里可以看到?

**回答**: 出于安全考虑,一旦添加 Secret,就**无法再查看**其值。

**可以进行的操作**:
- ✅ 更新（替换为新值）
- ✅ 删除
- ❌ 查看原值

**建议**: 在添加 Secret 前,将值保存在安全的密码管理器中。

---

### Q: Workflow 中使用 Secret 失败,显示为空?

**检查清单**:

1. **Secret 名称是否正确（区分大小写）**:
   ```yaml
   # ❌ 错误
   ${{ secrets.docker_token }}

   # ✅ 正确
   ${{ secrets.DOCKER_TOKEN }}
   ```

2. **Secret 是否已添加到仓库**:
   - 仓库 → Settings → Secrets → 检查是否存在

3. **Secret 作用域是否正确**:
   - 仓库级别 Secret: 只能在该仓库中使用
   - 组织级别 Secret: 需要仓库有访问权限

4. **Workflow 语法是否正确**:
   ```yaml
   # 确保使用双花括号和 secrets 前缀
   password: ${{ secrets.DOCKER_TOKEN }}
   ```

---

### Q: 如何更新已有的 Secret?

**步骤**:

1. 仓库 → Settings → Secrets
2. 找到要更新的 Secret
3. 点击 **Edit** 或 **Update** 按钮
4. 输入新值
5. 点击 **Save** 保存

**注意**: 更新后新值立即生效,后续 Workflow 会使用新值。

---

### Q: 可以在 Pull Request 中使用 Secrets 吗?

**回答**: 取决于 PR 来源

- ✅ **同一仓库的 PR**: 可以使用 Secrets
- ⚠️ **Fork 仓库的 PR**: **不能**使用 Secrets（安全限制）

**原因**: 防止恶意代码通过 Fork PR 窃取 Secrets

**解决方案**:
- 对于 Fork PR,仓库维护者需要手动触发 Workflow
- 或者贡献者将代码合并到临时分支再触发

---

## 性能优化

### Q: Workflow 执行时间过长怎么办?

**优化方案**:

1. **使用 Docker 层缓存**:
   ```yaml
   - name: Build and push
     uses: docker/build-push-action@v4
     with:
       cache-from: type=registry,ref=git.localhost:3000/user/repo:buildcache
       cache-to: type=registry,ref=git.localhost:3000/user/repo:buildcache,mode=max
   ```

2. **优化 Dockerfile**:
   - 减少构建层数
   - 将不常变化的层放在前面
   - 使用 `.dockerignore` 减少构建上下文

3. **使用更快的基础镜像**:
   ```dockerfile
   # 更快: alpine 版本
   FROM node:18-alpine

   # 较慢: 完整版本
   FROM node:18
   ```

4. **并行执行任务**:
   ```yaml
   jobs:
     test:
       # ...
     build:
       # 不依赖 test,可以并行执行
   ```

5. **增加 Runner 资源**:
   - 编辑 `docker-compose.yml`
   - 为 act_runner 服务增加 CPU 和内存限制

---

### Q: 如何提升构建速度?

**最佳实践**:

1. **使用多阶段构建**:
   ```dockerfile
   # 构建阶段
   FROM node:18 AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build

   # 运行阶段（更小）
   FROM node:18-alpine
   WORKDIR /app
   COPY --from=builder /app/dist ./dist
   CMD ["node", "dist/main.js"]
   ```

2. **使用依赖缓存**:
   ```yaml
   - name: Cache dependencies
     uses: actions/cache@v3
     with:
       path: ~/.npm
       key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
   ```

3. **减少镜像层数**:
   ```dockerfile
   # ✅ 好: 合并 RUN 命令
   RUN apt-get update && \
       apt-get install -y package1 package2 && \
       rm -rf /var/lib/apt/lists/*

   # ❌ 差: 多个 RUN 命令
   RUN apt-get update
   RUN apt-get install -y package1
   RUN apt-get install -y package2
   ```

---

## 数据管理

### Q: 如何备份数据?

**完整备份方案**:

```bash
# 1. 停止服务（推荐,确保数据一致性）
docker-compose down

# 2. 备份 data 目录
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/

# 3. 备份数据库（可选,data 目录已包含）
docker-compose up -d postgres
docker-compose exec postgres pg_dump -U gitea gitea > gitea-db-$(date +%Y%m%d).sql
docker-compose down

# 4. 备份配置文件
tar -czf config-backup-$(date +%Y%m%d).tar.gz .env docker-compose.yml gitea/ traefik/ postgres/

# 5. 重启服务
docker-compose up -d
```

**增量备份**（服务运行中）:

```bash
# 备份数据库
docker-compose exec -T postgres pg_dump -U gitea gitea | gzip > gitea-db-$(date +%Y%m%d).sql.gz

# 备份 Gitea 仓库数据
rsync -av --progress data/gitea/ backup/gitea-$(date +%Y%m%d)/
```

---

### Q: 如何恢复数据?

**从完整备份恢复**:

```bash
# 1. 停止服务
docker-compose down

# 2. 解压备份
tar -xzf backup-YYYYMMDD-HHMMSS.tar.gz

# 3. 恢复配置文件（如果需要）
tar -xzf config-backup-YYYYMMDD.tar.gz

# 4. 重启服务
docker-compose up -d
```

**只恢复数据库**:

```bash
# 1. 确保服务运行
docker-compose up -d

# 2. 恢复数据库
docker-compose exec -T postgres psql -U gitea gitea < gitea-db-YYYYMMDD.sql

# 或从压缩备份恢复
gunzip < gitea-db-YYYYMMDD.sql.gz | docker-compose exec -T postgres psql -U gitea gitea

# 3. 重启 Gitea
docker-compose restart gitea
```

---

### Q: 如何迁移到新服务器?

**步骤**:

1. **在旧服务器上备份**:
   ```bash
   docker-compose down
   tar -czf full-backup.tar.gz data/ .env docker-compose.yml gitea/ traefik/ postgres/
   ```

2. **传输到新服务器**:
   ```bash
   scp full-backup.tar.gz user@new-server:/path/to/destination/
   ```

3. **在新服务器上恢复**:
   ```bash
   # 安装 Docker 和 Docker Compose

   # 解压备份
   tar -xzf full-backup.tar.gz

   # 启动服务
   docker-compose up -d
   ```

4. **更新配置**（如果需要）:
   - 修改 `.env` 中的域名配置
   - 更新 DNS 记录指向新服务器
   - 配置 SSL 证书

---

## 其他问题

### Q: 如何查看服务日志?

**常用命令**:

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs gitea
docker-compose logs traefik
docker-compose logs postgres
docker-compose logs act_runner

# 实时跟踪日志
docker-compose logs -f gitea

# 查看最近100行日志
docker-compose logs --tail=100 gitea

# 查看特定时间段日志
docker-compose logs --since="2024-01-15T10:00:00" gitea
```

---

### Q: 如何更新服务版本?

**步骤**:

```bash
# 1. 备份当前数据
docker-compose down
tar -czf backup-before-update-$(date +%Y%m%d).tar.gz data/

# 2. 拉取最新镜像
docker-compose pull

# 3. 重新构建和启动
docker-compose up -d --build

# 4. 查看日志确认启动成功
docker-compose logs -f

# 5. 清理旧镜像
docker image prune -a
```

---

### Q: 如何卸载平台?

**完全卸载步骤**:

```bash
# 1. 停止并删除容器
docker-compose down

# 2. 删除数据卷（⚠️ 会删除所有数据）
docker volume rm $(docker volume ls -q | grep gitea)

# 3. 删除镜像（可选）
docker rmi $(docker images | grep 'gitea\|traefik\|postgres' | awk '{print $3}')

# 4. 删除项目目录
cd ..
rm -rf local-deploy-environment
```

**保留数据的卸载**:

```bash
# 1. 备份数据
tar -czf gitea-data-backup.tar.gz data/

# 2. 只删除容器
docker-compose down

# 3. 删除项目文件（保留备份）
# 手动移除,保留 gitea-data-backup.tar.gz
```

---

## 💡 找不到答案?

如果以上 FAQ 没有解决您的问题:

1. **查看详细文档**:
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 系统性故障排查
   - [CICD_GUIDE.md](CICD_GUIDE.md) - CI/CD 详细文档
   - [SECRETS_GUIDE.md](SECRETS_GUIDE.md) - Secrets 详细文档

2. **查看日志**:
   ```bash
   docker-compose logs
   ```

3. **检查官方文档**:
   - [Gitea 官方文档](https://docs.gitea.io/)
   - [Traefik 官方文档](https://doc.traefik.io/traefik/)

4. **提交 Issue**:
   - 描述问题症状
   - 提供相关日志
   - 说明环境配置

---

**最后更新**: 2024-01-15
