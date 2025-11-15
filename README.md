# 企业级代码托管平台 - Docker Compose 部署方案

基于 Docker Compose 编排的轻量级代码托管平台，适合 20 人以内的小团队使用。

## 📋 技术栈

- **代码托管**: [Gitea](https://gitea.io/) - 轻量级 Git 服务
- **数据库**: [PostgreSQL 15](https://www.postgresql.org/) - 关系型数据库
- **反向代理**: [Traefik v3](https://traefik.io/) - 现代化反向代理和负载均衡器

## 🚀 功能特性

### Gitea 功能
- ✅ Git 仓库托管
- ✅ Issue 跟踪系统
- ✅ Pull Request 和 Code Review
- ✅ Wiki 文档
- ✅ 项目看板（Kanban）
- ✅ Webhook 集成
- ✅ Git LFS 支持
- ✅ 轻量级 CI/CD (Gitea Actions)

### Traefik 功能
- ✅ 自动服务发现
- ✅ 动态配置更新
- ✅ 自动 HTTPS (Let's Encrypt)
- ✅ Dashboard 管理界面
- ✅ 健康检查和负载均衡

## 📁 项目结构

```
local-deploy-environment/
├── .env                          # 环境变量配置
├── docker-compose.yml            # Docker Compose 编排文件
├── README.md                     # 项目文档
│
├── doc/                          # 文档目录
│   ├── QUICKSTART.md            # 快速开始指南
│   ├── CICD_GUIDE.md            # CI/CD 完整指南
│   ├── QUICKSTART_CICD.md       # CI/CD 快速开始
│   ├── SECRETS_GUIDE.md         # Secrets 配置指南
│   ├── TEST_ACTIONS_MANUAL.md   # Actions 手动测试指南
│   ├── STRUCTURE.md             # 详细结构说明
│   ├── UPDATE_PASSWORD.md       # 密码更新指南
│   └── examples/
│       └── workflow-build-and-push.yml  # Workflow 示例
│
├── scripts/                      # 脚本目录
│   ├── start.sh                 # 启动脚本
│   ├── create-test-repo.sh      # 创建测试仓库
│   ├── push-test-repo.sh        # 推送测试仓库
│   └── test-actions.sh          # Actions 自动测试
│
├── traefik/                      # Traefik 配置
│   ├── Dockerfile
│   ├── traefik.yml              # 静态配置
│   └── dynamic/
│       └── dashboard.yml        # Dashboard 动态配置
│
├── gitea/                        # Gitea 配置
│   ├── Dockerfile
│   └── config/
│       └── app.ini              # 应用配置
│
├── act_runner/                   # Gitea Actions Runner 配置
│   └── Dockerfile
│
├── postgres/                     # PostgreSQL 配置
│   ├── Dockerfile
│   └── init.sql                 # 数据库初始化脚本
│
└── data/                         # 持久化数据目录
    ├── traefik/
    │   ├── acme.json           # SSL 证书
    │   └── logs/               # 访问日志
    ├── gitea/                   # Gitea 数据
    ├── postgres/                # 数据库数据
    └── act-runner/              # Runner 数据
```

## ⚙️ 快速开始

### 1. 环境要求

- Docker Engine 20.10+
- Docker Compose 2.0+
- 最低配置: 2GB RAM, 2 CPU 核心, 50GB 存储

### 2. 配置环境变量

编辑 `.env` 文件，修改以下关键配置：

```bash
# 域名配置（根据实际情况修改）
DOMAIN=localhost  # 或者你的实际域名，如 example.com

# Gitea 管理员配置（必须修改）
GITEA_ADMIN_USER=gitadmin
GITEA_ADMIN_PASSWORD=changeme123  # 请修改为强密码
GITEA_ADMIN_EMAIL=admin@example.com

# 数据库密码（必须修改）
POSTGRES_PASSWORD=changeme456  # 请修改为强密码

# Traefik Dashboard 密码（必须修改）
TRAEFIK_PASSWORD=changeme  # 请修改为强密码

# SSL 证书邮箱（如果使用 HTTPS）
ACME_EMAIL=admin@example.com
```

### 3. 启动服务

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 访问服务

- **Gitea**: http://git.localhost (或 http://git.yourdomain.com)
- **Traefik Dashboard**: http://traefik.localhost (或 http://traefik.yourdomain.com)
  - 用户名: `admin`
  - 密码: 在 `.env` 中配置的 `TRAEFIK_PASSWORD`

### 5. 初始化 Gitea

首次访问 Gitea 会进入安装向导，大部分配置已通过环境变量预设：

1. 数据库配置已自动填充，无需修改
2. 服务器域名和 URL 已自动配置
3. 创建管理员账户（使用 `.env` 中配置的账户）
4. 点击"安装 Gitea"完成初始化

## 🔧 常用命令

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 重新构建并启动
docker-compose up -d --build

# 查看运行状态
docker-compose ps

# 查看实时日志
docker-compose logs -f [service_name]
```

### 数据备份

```bash
# 备份 Gitea 数据
tar -czf gitea-backup-$(date +%Y%m%d).tar.gz data/gitea/

# 备份数据库
docker-compose exec postgres pg_dump -U gitea gitea > gitea-db-backup-$(date +%Y%m%d).sql

# 完整备份
tar -czf full-backup-$(date +%Y%m%d).tar.gz data/
```

### 数据恢复

```bash
# 恢复 Gitea 数据
tar -xzf gitea-backup-YYYYMMDD.tar.gz

# 恢复数据库
docker-compose exec -T postgres psql -U gitea gitea < gitea-db-backup-YYYYMMDD.sql
```

## 🔒 安全配置

### 1. 启用 HTTPS

如果你有自己的域名，可以启用 Let's Encrypt 自动 HTTPS：

1. 修改 `.env` 中的 `DOMAIN` 和 `ACME_EMAIL`
2. 取消 `traefik/traefik.yml` 中 HTTPS 相关配置的注释
3. 取消 `docker-compose.yml` 中 Gitea HTTPS 标签的注释
4. 重启服务: `docker-compose up -d`

### 2. 修改默认密码

**重要**: 部署后立即修改所有默认密码：

- Traefik Dashboard 密码
- Gitea 管理员密码
- PostgreSQL 数据库密码

### 3. 防火墙配置

```bash
# 只开放必要的端口
# HTTP
sudo ufw allow 80/tcp
# HTTPS
sudo ufw allow 443/tcp
# SSH (Gitea)
sudo ufw allow 2222/tcp
```

## 📝 配置说明

### Gitea SSH 端口

默认 SSH 端口映射到宿主机的 `2222`，克隆仓库时使用：

```bash
# HTTPS 克隆
git clone http://git.localhost/username/repo.git

# SSH 克隆
git clone ssh://git@git.localhost:2222/username/repo.git
```

### Traefik Dashboard 认证

修改 Dashboard 密码：

```bash
# 生成新的密码哈希
echo $(htpasswd -nb admin your-new-password)

# 或使用在线工具: https://hostingcanada.org/htpasswd-generator/

# 将生成的字符串更新到 traefik/dynamic/dashboard.yml
```

## 🛠️ 故障排查

### 服务无法启动

```bash
# 检查日志
docker-compose logs

# 检查端口占用
sudo netstat -tlnp | grep -E '(80|443|2222)'

# 清理并重启
docker-compose down
docker-compose up -d
```

### 数据库连接失败

```bash
# 检查数据库健康状态
docker-compose exec postgres pg_isready -U gitea

# 查看数据库日志
docker-compose logs postgres
```

### Traefik 路由不工作

```bash
# 检查 Traefik 日志
docker-compose logs traefik

# 访问 Dashboard 查看路由配置
http://traefik.localhost
```

## 📊 性能优化

### 资源限制

在 `docker-compose.yml` 中添加资源限制：

```yaml
services:
  gitea:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 512M
```

### 数据库优化

编辑 PostgreSQL 配置以优化性能（适用于生产环境）。

## 🔄 更新升级

```bash
# 拉取最新镜像
docker-compose pull

# 重建并重启服务
docker-compose up -d --build

# 清理旧镜像
docker image prune -a
```

## 📚 文档索引

### 快速开始
- [QUICKSTART.md](doc/QUICKSTART.md) - 平台快速开始指南
- [QUICKSTART_CICD.md](doc/QUICKSTART_CICD.md) - CI/CD 功能快速开始

### 完整指南
- [CICD_GUIDE.md](doc/CICD_GUIDE.md) - CI/CD 完整使用指南
- [SECRETS_GUIDE.md](doc/SECRETS_GUIDE.md) - Secrets 配置详细指南
- [TEST_ACTIONS_MANUAL.md](doc/TEST_ACTIONS_MANUAL.md) - Gitea Actions 手动测试指南
- [UPDATE_PASSWORD.md](doc/UPDATE_PASSWORD.md) - 密码更新指南

### 项目信息
- [STRUCTURE.md](doc/STRUCTURE.md) - 详细项目结构说明

### 示例文件
- [workflow-build-and-push.yml](doc/examples/workflow-build-and-push.yml) - 完整的 Docker 镜像构建和推送 workflow 示例

### 官方文档
- [Gitea 官方文档](https://docs.gitea.io/)
- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

**注意**: 这是一个生产就绪的配置，但在正式部署前请务必：
1. 修改所有默认密码
2. 根据实际需求调整配置
3. 配置定期备份
4. 启用 HTTPS（生产环境必须）
