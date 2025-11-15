# 修改 Traefik Dashboard 密码指南

## 方法一：使用在线工具（推荐，简单）

1. 访问在线密码哈希生成器：
   - https://hostingcanada.org/htpasswd-generator/
   - 或 https://www.web2generators.com/apache-tools/htpasswd-generator

2. 输入：
   - **Username**: `admin`（或你想要的用户名）
   - **Password**: 你的新密码

3. 点击生成，复制生成的哈希字符串（格式类似：`admin:$apr1$xxx$xxx`）

4. 编辑 `.env` 文件：
   ```bash
   # 修改 TRAEFIK_PASSWORD_HASH
   TRAEFIK_PASSWORD_HASH=admin:$$apr1$$你复制的哈希值
   ```

   ⚠️ **重要**: 在 `.env` 文件中，`$` 需要转义为 `$$`

5. 重启 Traefik：
   ```bash
   docker-compose up -d --force-recreate traefik
   ```

## 方法二：使用 htpasswd 命令

如果你的系统已安装 `htpasswd` 工具（通常在 apache2-utils 包中）：

### Linux/macOS

```bash
# 1. 生成密码哈希（推荐使用 bcrypt，更安全）
htpasswd -nbB admin 你的新密码

# 或使用 APR1（兼容性更好，但安全性稍低）
htpasswd -nb admin 你的新密码

# 2. 复制输出结果（类似: admin:$apr1$xxx$xxx）

# 3. 编辑 .env 文件
# 将 $ 替换为 $$
TRAEFIK_PASSWORD_HASH=admin:$$apr1$$xxx$$xxx

# 4. 重启 Traefik
docker-compose up -d --force-recreate traefik
```

### Windows (WSL/Git Bash)

```bash
# 1. 安装 htpasswd（如果没有）
# WSL Ubuntu/Debian:
sudo apt-get install apache2-utils

# WSL CentOS/RHEL:
sudo yum install httpd-tools

# 2. 生成密码哈希
htpasswd -nb admin 你的新密码

# 3-4. 同上
```

## 方法三：使用 Docker 容器生成（推荐）

如果你没有 htpasswd 工具，可以使用 Docker：

```bash
# 1. 使用 Docker 生成密码哈希（推荐 bcrypt）
docker run --rm httpd:alpine htpasswd -nbB admin 你的新密码

# 或使用 APR1
docker run --rm httpd:alpine htpasswd -nb admin 你的新密码

# 2. 复制输出并更新 .env 文件（记得转义 $）
TRAEFIK_PASSWORD_HASH=admin:$$apr1$$xxx$$xxx

# 3. 重启 Traefik
docker-compose up -d --force-recreate traefik
```

## 示例

假设你想设置密码为 `MySecurePass123`：

### 步骤1: 生成哈希（使用 bcrypt）
```bash
$ docker run --rm httpd:alpine htpasswd -nbB admin MySecurePass123
admin:$2y$05$XmK7nR8pLqS9vT4wU6bN5OzJhGfP2aQ8cR1dE3fG4hI5jK6lM7nO8
```

### 步骤2: 编辑 .env
```bash
# 注意 $ 要转义为 $$
TRAEFIK_PASSWORD_HASH=admin:$$2y$$05$$XmK7nR8pLqS9vT4wU6bN5OzJhGfP2aQ8cR1dE3fG4hI5jK6lM7nO8
```

### 步骤3: 重启服务
```bash
docker-compose up -d --force-recreate traefik
```

## 验证

1. 访问 http://traefik.localhost
2. 输入用户名和新密码
3. 应该能够成功登录

## 故障排查

### 问题1: 仍然提示密码错误

**解决方案**:
- 确保 `.env` 文件中的 `$` 已经转义为 `$$`
- 检查是否有多余的空格或换行符
- 重启容器: `docker-compose up -d --force-recreate traefik`

### 问题2: 不提示输入密码

**解决方案**:
- 检查 `docker-compose.yml` 中是否包含认证中间件配置
- 查看 Traefik 日志: `docker-compose logs traefik`
- 确保 `.env` 文件中有 `TRAEFIK_PASSWORD_HASH` 变量

### 问题3: 生成的哈希无效

**解决方案**:
- 使用在线工具重新生成
- 确保使用的是 APR1 或 MD5 格式（最兼容）
- 避免使用特殊字符（如 `$`, `"`, `'` 等）在密码中

## 安全建议

1. ✅ 使用强密码（至少12位，包含大小写字母、数字和符号）
2. ✅ 定期更换密码
3. ✅ 不要在 Git 仓库中提交包含真实密码的 `.env` 文件
4. ✅ 对于生产环境，考虑使用更强的认证方式（如 OAuth2）
5. ✅ 启用 HTTPS（生产环境必须）

## 相关文件

- [.env](.env) - 环境变量配置文件
- [docker-compose.yml](docker-compose.yml) - 服务编排文件
- [README.md](README.md) - 项目主文档
