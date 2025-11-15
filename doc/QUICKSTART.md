# 🚀 快速开始指南

## 一、部署前准备（5分钟）

### 1. 修改配置文件

编辑 [.env](.env) 文件，**必须修改**以下密码：

```bash
# 修改这些密码！
GITEA_ADMIN_PASSWORD=changeme123      # ← 改成强密码
POSTGRES_PASSWORD=changeme456         # ← 改成强密码
TRAEFIK_PASSWORD=changeme             # ← 改成强密码

# 如果有域名，修改这个
DOMAIN=localhost                      # ← 改成你的域名，如 example.com
```

### 2. （可选）配置域名解析

如果使用域名，需要添加 DNS 记录：

```
A    git.yourdomain.com       → 服务器IP
A    traefik.yourdomain.com   → 服务器IP
```

本地测试可以修改 `/etc/hosts` (Linux/Mac) 或 `C:\Windows\System32\drivers\etc\hosts` (Windows)：

```
127.0.0.1  git.localhost
127.0.0.1  traefik.localhost
```

---

## 二、启动服务（2分钟）

### 方式1: 使用启动脚本（推荐）

```bash
./start.sh
```

### 方式2: 手动启动

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

---

## 三、初始化 Gitea（3分钟）

### 1. 访问 Gitea

浏览器打开: http://git.localhost （或你的域名）

### 2. 完成安装向导

大部分配置已自动填充，只需：

1. **数据库设置** - 已自动配置 ✓
2. **常规设置** - 已自动配置 ✓
3. **管理员账户** - 填写管理员信息（使用 `.env` 中配置的账户）
4. 点击 **"安装 Gitea"**

### 3. 登录系统

- 用户名: `gitadmin`（或你在 `.env` 中设置的）
- 密码: 你在 `.env` 中设置的密码

---

## 四、开始使用

### 创建第一个仓库

1. 点击右上角 **"+"** → **"新建仓库"**
2. 填写仓库名称和描述
3. 选择公开或私有
4. 点击 **"创建仓库"**

### 克隆仓库

**HTTPS 方式:**
```bash
git clone http://git.localhost/username/repo.git
```

**SSH 方式:**
```bash
# 先添加 SSH 公钥到 Gitea (设置 → SSH/GPG 密钥)
git clone ssh://git@git.localhost:2222/username/repo.git
```

---

## 五、常用操作

### 服务管理

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f gitea

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 停止并删除数据卷（危险！会删除所有数据）
docker-compose down -v
```

### 数据备份

```bash
# 完整备份
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# 只备份 Gitea 数据
tar -czf gitea-backup-$(date +%Y%m%d).tar.gz data/gitea/

# 备份数据库
docker-compose exec postgres pg_dump -U gitea gitea > db-backup-$(date +%Y%m%d).sql
```

### 更新升级

```bash
# 拉取最新镜像
docker-compose pull

# 重建并重启
docker-compose up -d --build

# 清理旧镜像
docker image prune -a
```

---

## 六、访问服务

| 服务 | 地址 | 用途 |
|------|------|------|
| **Gitea** | http://git.localhost | 代码托管平台 |
| **Traefik Dashboard** | http://traefik.localhost | 查看路由和服务状态 |

**Traefik Dashboard 登录:**
- 用户名: `admin`
- 密码: 在 `.env` 中设置的 `TRAEFIK_PASSWORD`

---

## 七、故障排查

### 服务启动失败

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
sudo netstat -tlnp | grep -E '(80|443|2222)'

# 清理并重启
docker-compose down
docker-compose up -d
```

### 无法访问 Gitea

1. 检查服务是否运行: `docker-compose ps`
2. 检查日志: `docker-compose logs gitea`
3. 检查防火墙: `sudo ufw status`
4. 检查 hosts 文件配置

### 忘记管理员密码

```bash
# 进入容器重置密码
docker-compose exec gitea gitea admin user change-password --username gitadmin --password 新密码
```

---

## 八、下一步

- 📖 查看完整文档: [README.md](README.md)
- 🏗️ 了解项目结构: [STRUCTURE.md](STRUCTURE.md)
- 🔒 配置 HTTPS: 查看 README 中的"安全配置"章节
- 📧 配置邮件通知: 编辑 `gitea/config/app.ini` 中的 `[mailer]` 部分

---

## 需要帮助？

- Gitea 文档: https://docs.gitea.io/
- Traefik 文档: https://doc.traefik.io/
- Docker Compose 文档: https://docs.docker.com/compose/

---

**祝使用愉快！** 🎉
