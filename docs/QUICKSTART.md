# 🚀 快速开始指南

本指南帮助您在 15 分钟内完成平台部署和初始化。

---

## 一、部署前准备（5分钟）

### 1. 环境要求

- Docker Engine 20.10+
- Docker Compose 2.0+
- 最低配置: 2GB RAM, 2 CPU 核心, 50GB 存储

### 2. 修改配置文件

编辑项目根目录的 `.env` 文件，**必须修改**以下密码：

```bash
# ⚠️ 安全提示: 修改这些默认密码！
GITEA_ADMIN_PASSWORD=changeme123      # ← 改成强密码
POSTGRES_PASSWORD=changeme456         # ← 改成强密码
TRAEFIK_PASSWORD=changeme             # ← 改成强密码

# 如果有域名，修改这个
DOMAIN=localhost                      # ← 改成你的域名，如 example.com
```

**密码要求**:
- 至少 8 位字符
- 包含大小写字母、数字和特殊字符
- 避免使用常见密码

### 3. （可选）配置域名

**生产环境**: 配置 DNS 记录

```
A    git.yourdomain.com       → 服务器IP
A    traefik.yourdomain.com   → 服务器IP
```

**本地测试**: 修改 hosts 文件

```bash
# Linux/Mac
sudo nano /etc/hosts
# 添加:
127.0.0.1  git.localhost traefik.localhost

# Windows (管理员权限)
# 编辑 C:\Windows\System32\drivers\etc\hosts
# 添加:
127.0.0.1  git.localhost traefik.localhost
```

---

## 二、启动服务（2分钟）

### 方式1: 使用启动脚本（推荐）

```bash
# 确保脚本有执行权限
chmod +x scripts/start.sh

# 运行启动脚本
./scripts/start.sh
```

### 方式2: 手动启动

```bash
# 1. 构建镜像
docker-compose build

# 2. 启动所有服务
docker-compose up -d

# 3. 查看服务状态
docker-compose ps

# 4. 查看启动日志
docker-compose logs -f
```

**预期输出**:

```
NAME                COMMAND                  STATUS
gitea               "/usr/bin/entrypoint…"   Up
postgres            "docker-entrypoint.s…"   Up
traefik             "/entrypoint.sh trae…"   Up
act_runner          "/sbin/tini -- /bin/…"   Up
```

---

## 三、初始化 Gitea（3分钟）

### 1. 访问 Gitea

浏览器打开: **http://git.localhost** （或你配置的域名）

### 2. 完成安装向导

首次访问会显示安装页面,大部分配置已自动填充：

**数据库设置** (已自动配置,无需修改):
- 数据库类型: PostgreSQL
- 主机: postgres:5432
- 数据库名: gitea
- 用户名: gitea

**常规设置** (已自动配置,可选修改):
- 网站标题: Gitea: Git with a cup of tea
- 仓库根目录: /data/git/repositories
- SSH 服务器域名: git.localhost
- SSH 端口: 2222
- HTTP(S) URL: http://git.localhost/

**管理员账户**（必须填写）:
- 管理员用户名: `gitadmin` (与 `.env` 中一致)
- 密码: 您在 `.env` 中设置的 `GITEA_ADMIN_PASSWORD`
- 邮箱: 您在 `.env` 中设置的邮箱

填写完成后,点击 **"安装 Gitea"** 按钮。

### 3. 登录系统

安装完成后会自动跳转到登录页面:

- 用户名: `gitadmin` (或您设置的管理员用户名)
- 密码: 您设置的管理员密码

---

## 四、开始使用

### 创建第一个仓库

1. 点击右上角 **"+"** 图标 → **"新建仓库"**
2. 填写仓库信息:
   - 仓库名称: 如 `my-first-repo`
   - 描述: 可选
   - 可见性: 公开 或 私有
   - 初始化仓库: 可选勾选 "添加 README 文件"
3. 点击 **"创建仓库"**

### 克隆仓库

**HTTPS 方式** (推荐新手):

```bash
git clone http://git.localhost/username/repo.git
cd repo

# 配置用户信息
git config user.name "Your Name"
git config user.email "your@email.com"

# 提交更改
git add .
git commit -m "Initial commit"
git push
```

**SSH 方式**:

```bash
# 1. 生成 SSH 密钥(如果还没有)
ssh-keygen -t ed25519 -C "your@email.com"

# 2. 复制公钥
cat ~/.ssh/id_ed25519.pub

# 3. 在 Gitea 中添加 SSH 公钥
# 设置 → SSH/GPG 密钥 → 添加密钥

# 4. 克隆仓库
git clone ssh://git@git.localhost:2222/username/repo.git
```

### 邀请团队成员

1. 进入仓库 → **"设置"** → **"协作者"**
2. 输入用户名,选择权限级别:
   - **读取**: 只能查看和克隆
   - **写入**: 可以推送代码
   - **管理员**: 完全控制
3. 点击 **"添加协作者"**

---

## 五、基础操作

### 服务管理

```bash
# 查看服务状态
docker-compose ps

# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs gitea
docker-compose logs -f gitea  # 实时跟踪

# 重启服务
docker-compose restart

# 重启特定服务
docker-compose restart gitea

# 停止服务
docker-compose stop

# 启动服务
docker-compose start

# 停止并删除容器(保留数据)
docker-compose down
```

### 访问服务面板

| 服务 | 地址 | 用途 |
|------|------|------|
| **Gitea** | http://git.localhost | 代码托管平台 |
| **Traefik Dashboard** | http://traefik.localhost | 查看路由和服务状态 |

**Traefik Dashboard 登录**:
- 用户名: `admin`
- 密码: 在 `.env` 中设置的 `TRAEFIK_PASSWORD`

---

## 六、下一步

### 基础功能

- ✅ **探索仓库功能**: 创建 Issue, Pull Request, Wiki
- ✅ **配置 CI/CD**: 参考 [CICD_GUIDE.md](CICD_GUIDE.md)
- ✅ **管理组织**: 创建组织,管理团队和权限

### 进阶配置

- 🔒 **启用 HTTPS**: 参考主 [README.md](../README.md) 的"安全配置"章节
- 📧 **配置邮件通知**: 编辑 `gitea/app.ini` 中的 `[mailer]` 部分
- 🔐 **配置 OAuth 登录**: 支持 GitHub, GitLab, Google 等
- 💾 **设置定期备份**: 参考 [FAQ.md](FAQ.md) 的"数据管理"部分

### 学习更多

- 📖 **完整文档**: 查看 [doc/README.md](README.md) 了解所有文档
- 🏗️ **项目结构**: [STRUCTURE.md](STRUCTURE.md) 理解目录组织
- ❓ **常见问题**: [FAQ.md](FAQ.md) 快速找到答案
- 🔧 **故障排查**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 深度调试

---

## 遇到问题?

**快速检查**:

```bash
# 1. 检查所有服务是否运行
docker-compose ps

# 2. 查看错误日志
docker-compose logs | grep -i error

# 3. 检查端口占用
sudo netstat -tlnp | grep -E '(80|443|2222)'
```

**获取帮助**:

1. 查看 [FAQ.md](FAQ.md) 中的常见问题
2. 查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 进行系统性排查
3. 查看官方文档:
   - [Gitea 文档](https://docs.gitea.io/)
   - [Traefik 文档](https://doc.traefik.io/)
   - [Docker Compose 文档](https://docs.docker.com/compose/)

---

**祝使用愉快！** 🎉
