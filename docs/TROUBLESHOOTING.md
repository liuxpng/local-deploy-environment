# 故障排查指南

本文档提供系统性的故障排查方法和深度调试技巧,帮助您诊断和解决复杂问题。

> **提示**: 如果您在寻找常见问题的快速解答,请查看 [FAQ.md](FAQ.md)

---

## 📋 目录

- [诊断工具](#诊断工具)
- [常见故障模式](#常见故障模式)
- [日志分析](#日志分析)
- [网络诊断](#网络诊断)
- [性能问题排查](#性能问题排查)
- [深度调试技巧](#深度调试技巧)

---

## 诊断工具

### 容器状态检查

```bash
# 查看所有容器状态
docker-compose ps

# 查看容器详细信息
docker inspect <container_name>

# 查看容器资源使用情况
docker stats

# 查看容器进程
docker-compose top
```

### 服务健康检查

```bash
# 检查 Gitea 健康状态
curl -I http://git.localhost/api/healthz

# 检查 Traefik 健康状态
curl -I http://traefik.localhost/ping

# 检查 PostgreSQL 健康状态
docker-compose exec postgres pg_isready -U gitea
```

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志(最近100行)
docker-compose logs --tail=100 gitea

# 实时跟踪日志
docker-compose logs -f gitea

# 查看特定时间段日志
docker-compose logs --since="2024-01-15T10:00:00" --until="2024-01-15T11:00:00" gitea

# 搜索日志中的错误
docker-compose logs gitea | grep -i error
docker-compose logs gitea | grep -i warning
```

### 网络诊断

```bash
# 查看 Docker 网络
docker network ls
docker network inspect <network_name>

# 检查端口监听
sudo netstat -tlnp | grep -E '(80|443|2222|3000|5432)'

# 或使用 ss 命令
sudo ss -tlnp | grep -E '(80|443|2222|3000|5432)'

# 测试端口连通性
nc -zv localhost 80
nc -zv localhost 2222
nc -zv localhost 3000

# 从容器内测试网络
docker-compose exec gitea ping postgres
docker-compose exec gitea curl -I http://traefik
```

### 存储诊断

```bash
# 查看磁盘使用情况
df -h

# 查看 Docker 存储使用
docker system df

# 查看数据卷信息
docker volume ls
docker volume inspect gitea-data
docker volume inspect postgres-data

# 查看数据卷大小
sudo du -sh /var/lib/docker/volumes/*
```

---

## 常见故障模式

### 模式1: 服务无法启动

**症状识别**:
- `docker-compose ps` 显示服务状态为 `Exit` 或 `Restarting`
- 容器不断重启
- 日志中出现启动错误

**系统性排查流程**:

```bash
# 步骤1: 查看容器状态
docker-compose ps

# 步骤2: 查看失败服务的日志
docker-compose logs <service_name>

# 步骤3: 检查配置文件语法
docker-compose config

# 步骤4: 检查端口占用
sudo netstat -tlnp | grep <port>

# 步骤5: 检查磁盘空间
df -h

# 步骤6: 检查文件权限
ls -l data/

# 步骤7: 尝试单独启动问题服务
docker-compose up <service_name>
```

**常见原因和解决方案**:

| 原因 | 诊断方法 | 解决方案 |
|------|----------|----------|
| 端口冲突 | `netstat -tlnp \| grep <port>` | 修改端口映射或停止占用端口的服务 |
| 配置文件错误 | `docker-compose config` | 检查 YAML 语法和缩进 |
| 权限问题 | 日志中出现 "permission denied" | `sudo chown -R 1000:1000 data/` |
| 磁盘空间不足 | `df -h` | 清理磁盘空间 |
| 依赖服务未就绪 | 服务启动顺序问题 | 添加 `depends_on` 或健康检查 |

---

### 模式2: 网络连接问题

**症状识别**:
- 无法访问服务 UI
- 服务间无法通信
- DNS 解析失败

**系统性排查流程**:

```bash
# 步骤1: 检查容器网络配置
docker network inspect <project>_default

# 步骤2: 检查 DNS 解析
docker-compose exec gitea nslookup postgres
docker-compose exec gitea ping postgres

# 步骤3: 检查防火墙规则
sudo ufw status
sudo iptables -L -n

# 步骤4: 检查 Traefik 路由
docker-compose logs traefik | grep -i router

# 步骤5: 测试从宿主机访问
curl -v http://localhost:80
curl -v http://git.localhost

# 步骤6: 检查 hosts 文件(本地部署)
cat /etc/hosts | grep localhost
```

**网络层次诊断**:

```
层次1: 容器内部
  ↓ docker-compose exec gitea ping 127.0.0.1

层次2: 容器间通信
  ↓ docker-compose exec gitea ping postgres

层次3: 容器到宿主机
  ↓ docker-compose exec gitea ping host.docker.internal

层次4: 宿主机到容器
  ↓ curl http://localhost:3000

层次5: 外部访问
  ↓ curl http://git.localhost
```

---

### 模式3: 数据库连接失败

**症状识别**:
- Gitea 日志显示 "database connection failed"
- 服务启动后立即退出
- 数据库查询超时

**系统性排查流程**:

```bash
# 步骤1: 检查 PostgreSQL 是否运行
docker-compose ps postgres

# 步骤2: 检查数据库健康状态
docker-compose exec postgres pg_isready -U gitea

# 步骤3: 测试数据库连接
docker-compose exec postgres psql -U gitea -d gitea -c "SELECT 1;"

# 步骤4: 检查数据库日志
docker-compose logs postgres | grep -i error

# 步骤5: 验证连接参数
docker-compose exec gitea env | grep DB

# 步骤6: 测试从 Gitea 连接数据库
docker-compose exec gitea nc -zv postgres 5432
```

**数据库常见问题**:

```bash
# 问题1: 数据库未初始化
# 解决: 删除卷并重新创建
docker-compose down
docker volume rm postgres-data
docker-compose up -d

# 问题2: 连接数超限
# 查看当前连接数
docker-compose exec postgres psql -U gitea -d gitea -c \
  "SELECT count(*) FROM pg_stat_activity;"

# 修改最大连接数(在 postgres/Dockerfile 或配置中)
# max_connections = 200

# 问题3: 数据库锁
# 查看锁情况
docker-compose exec postgres psql -U gitea -d gitea -c \
  "SELECT * FROM pg_locks WHERE NOT granted;"
```

---

### 模式4: CI/CD Workflow 问题

**症状识别**:
- Workflow 不触发
- Workflow 一直 Waiting
- Workflow 执行失败

**系统性排查流程**:

```bash
# 步骤1: 检查 Actions 是否启用
docker-compose exec gitea env | grep GITEA__actions__ENABLED

# 步骤2: 检查 Runner 状态
docker-compose logs act_runner | tail -50

# 步骤3: 检查 Workflow 文件
# 确认路径: .gitea/workflows/*.yml
git ls-files .gitea/workflows/

# 步骤4: 验证 Workflow 语法
# 使用在线工具: https://www.yamllint.com/

# 步骤5: 查看 Gitea Actions 日志
docker-compose logs gitea | grep -i action

# 步骤6: 检查 Runner 注册状态
# Gitea UI: Site Administration → Actions → Runners
```

**Workflow 调试技巧**:

```yaml
# 在 Workflow 中添加调试步骤
steps:
  - name: Debug Environment
    run: |
      echo "=== Environment Variables ==="
      env | sort

      echo "=== Working Directory ==="
      pwd
      ls -la

      echo "=== Git Status ==="
      git status
      git log --oneline -5

      echo "=== System Info ==="
      uname -a
      df -h
      free -h
```

---

## 日志分析

### 日志级别和含义

| 级别 | 含义 | 关注度 |
|------|------|--------|
| FATAL | 致命错误,服务无法继续 | 🔴 立即处理 |
| ERROR | 错误,功能异常 | 🟠 高优先级 |
| WARN | 警告,潜在问题 | 🟡 中优先级 |
| INFO | 信息,正常运行 | 🟢 记录备查 |
| DEBUG | 调试信息 | 🔵 开发调试 |

### 日志分析技巧

```bash
# 1. 按级别过滤日志
docker-compose logs gitea | grep "ERROR"
docker-compose logs gitea | grep -E "ERROR|FATAL"

# 2. 统计错误数量
docker-compose logs gitea | grep "ERROR" | wc -l

# 3. 查找特定时间的日志
docker-compose logs --since="1h" gitea | grep "ERROR"

# 4. 日志去重(查看唯一错误)
docker-compose logs gitea | grep "ERROR" | sort | uniq

# 5. 提取请求日志
docker-compose logs traefik | grep "GET\|POST\|PUT\|DELETE"

# 6. 分析慢查询
docker-compose logs postgres | grep "duration:"
```

### 常见错误模式识别

```bash
# PostgreSQL 连接错误
docker-compose logs gitea | grep "connection refused\|connection reset"

# 权限错误
docker-compose logs | grep "permission denied\|403\|401"

# 资源不足
docker-compose logs | grep "out of memory\|no space left"

# 网络超时
docker-compose logs | grep "timeout\|connection timeout"

# 配置错误
docker-compose logs | grep "invalid configuration\|parse error"
```

---

## 网络诊断

### Traefik 路由调试

```bash
# 1. 查看所有路由
curl http://traefik.localhost/api/http/routers | jq

# 2. 查看特定路由配置
docker-compose logs traefik | grep -i "router.*gitea"

# 3. 测试路由匹配
curl -H "Host: git.localhost" http://localhost/

# 4. 查看中间件
curl http://traefik.localhost/api/http/middlewares | jq

# 5. 检查后端服务
curl http://traefik.localhost/api/http/services | jq
```

### DNS 问题诊断

```bash
# 1. 检查 hosts 文件
cat /etc/hosts | grep localhost

# 2. 测试 DNS 解析
nslookup git.localhost
dig git.localhost

# 3. 从容器内测试
docker-compose exec gitea nslookup postgres
docker-compose exec gitea getent hosts postgres

# 4. 检查 Docker DNS 设置
docker inspect <container> | grep -A 5 "Dns"
```

---

## 性能问题排查

### 资源使用监控

```bash
# 1. 实时监控容器资源
docker stats

# 2. 查看特定容器资源限制
docker inspect gitea | grep -A 10 "Memory"

# 3. 查看宿主机资源
top
htop  # 如果已安装
free -h
df -h

# 4. 查看 I/O 性能
iostat -x 1  # 如果已安装 sysstat
```

### 性能瓶颈识别

```bash
# 1. 数据库性能
# 查看慢查询
docker-compose exec postgres psql -U gitea -d gitea -c \
  "SELECT query, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# 查看活跃查询
docker-compose exec postgres psql -U gitea -d gitea -c \
  "SELECT pid, usename, application_name, state, query FROM pg_stat_activity WHERE state != 'idle';"

# 2. 网络性能
# 测试网络延迟
docker-compose exec gitea ping -c 10 postgres

# 测试带宽
# 在两个容器间使用 iperf3

# 3. 磁盘 I/O
# 测试写入性能
docker-compose exec gitea dd if=/dev/zero of=/tmp/test bs=1M count=100 oflag=direct

# 测试读取性能
docker-compose exec gitea dd if=/tmp/test of=/dev/null bs=1M iflag=direct
```

### 性能优化建议

```bash
# 1. 启用 PostgreSQL 查询缓存
# 在 postgres 配置中:
# shared_buffers = 256MB
# effective_cache_size = 1GB

# 2. 优化 Docker 日志大小
# 在 docker-compose.yml 中添加:
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

# 3. 使用 tmpfs 提升性能
# 在 docker-compose.yml 中:
tmpfs:
  - /tmp
  - /var/run

# 4. 限制容器资源避免资源争抢
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      memory: 512M
```

---

## 深度调试技巧

### 进入容器调试

```bash
# 1. 以 root 进入容器
docker-compose exec -u root gitea bash

# 2. 以服务用户进入
docker-compose exec gitea bash

# 3. 在容器中安装调试工具
docker-compose exec -u root gitea sh -c \
  "apt-get update && apt-get install -y curl vim net-tools"

# 4. 查看容器内进程
docker-compose exec gitea ps aux

# 5. 查看容器内端口监听
docker-compose exec gitea netstat -tlnp
```

### 使用 tcpdump 抓包

```bash
# 1. 在容器中抓包
docker-compose exec -u root gitea tcpdump -i any -w /tmp/capture.pcap

# 2. 复制到宿主机分析
docker cp <container_id>:/tmp/capture.pcap ./
wireshark capture.pcap

# 3. 实时查看 HTTP 请求
docker-compose exec -u root traefik tcpdump -i any -A 'tcp port 80'
```

### 调试 Docker 构建

```bash
# 1. 逐层构建查看问题
docker build --target <stage_name> -t debug-image .

# 2. 查看构建历史
docker history <image_name>

# 3. 使用 dive 分析镜像层
# 安装 dive: https://github.com/wagoodman/dive
dive <image_name>

# 4. 构建时不使用缓存
docker-compose build --no-cache <service_name>
```

### 启用详细日志

```bash
# 1. Gitea 详细日志
# 在 gitea/app.ini 中:
[log]
MODE = console
LEVEL = Debug

# 2. Traefik 详细日志
# 在 traefik/traefik.yml 中:
log:
  level: DEBUG

# 3. PostgreSQL 详细日志
# 在 postgres 配置中:
log_statement = 'all'
log_duration = on
```

---

## 紧急恢复流程

### 服务完全无响应

```bash
# 1. 强制停止所有容器
docker-compose down -t 0

# 2. 检查并清理异常容器
docker ps -a
docker container prune

# 3. 检查网络
docker network ls
docker network prune

# 4. 重新启动
docker-compose up -d

# 5. 监控启动过程
docker-compose logs -f
```

### 数据损坏恢复

```bash
# 1. 立即停止服务
docker-compose down

# 2. 备份当前数据(即使损坏也要备份)
cp -r data/ data-backup-$(date +%Y%m%d-%H%M%S)/

# 3. 尝试从最近备份恢复
# (参考 FAQ.md 中的数据恢复步骤)

# 4. 如果无备份,尝试数据库修复
docker-compose up -d postgres
docker-compose exec postgres pg_resetwal /var/lib/postgresql/data
```

---

## 调试检查清单

### 部署前检查

- [ ] Docker 和 Docker Compose 版本符合要求
- [ ] 端口 80, 443, 2222, 3000, 5432 未被占用
- [ ] 磁盘空间充足(至少 20GB 可用)
- [ ] `.env` 文件配置正确
- [ ] 防火墙规则已配置

### 启动后检查

- [ ] 所有服务状态为 `Up`
- [ ] 无错误日志
- [ ] 可以访问 Traefik Dashboard
- [ ] 可以访问 Gitea
- [ ] 数据库连接正常

### CI/CD 检查

- [ ] Runner 已注册且状态为 Idle
- [ ] Workflow 文件路径正确(`.gitea/workflows/`)
- [ ] Secrets 已正确配置
- [ ] 镜像仓库可以推送和拉取

---

## 获取帮助

如果问题仍未解决:

1. **收集诊断信息**:
   ```bash
   # 生成诊断报告
   echo "=== Docker Version ===" > diagnostic-report.txt
   docker version >> diagnostic-report.txt
   echo "\n=== Docker Compose Version ===" >> diagnostic-report.txt
   docker-compose version >> diagnostic-report.txt
   echo "\n=== Container Status ===" >> diagnostic-report.txt
   docker-compose ps >> diagnostic-report.txt
   echo "\n=== Recent Logs ===" >> diagnostic-report.txt
   docker-compose logs --tail=100 >> diagnostic-report.txt
   ```

2. **查看其他文档**:
   - [FAQ.md](FAQ.md) - 常见问题快速解答
   - [CICD_GUIDE.md](CICD_GUIDE.md) - CI/CD 详细文档

3. **提交 Issue**:
   - 附上诊断报告
   - 描述复现步骤
   - 说明环境配置

---

**最后更新**: 2024-01-15
