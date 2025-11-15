# 文档导航

欢迎使用企业级代码托管平台文档。本目录包含所有详细文档,帮助您快速部署和使用平台的各项功能。

## 📖 文档结构

### 🚀 快速开始

**首次部署用户,请从这里开始:**

- **[QUICKSTART.md](QUICKSTART.md)** - 平台部署快速指南
  - 环境要求和准备
  - 服务启动和初始化
  - 基本配置和使用
  - 预计阅读时间: 15分钟

### 📚 功能指南

**深入了解各项功能的详细使用方法:**

- **[CICD_GUIDE.md](CICD_GUIDE.md)** - CI/CD 完整使用指南
  - Gitea Actions 配置和使用
  - Runner 管理
  - Workflow 编写和调试
  - 容器镜像仓库使用
  - 预计阅读时间: 30分钟

- **[SECRETS_GUIDE.md](SECRETS_GUIDE.md)** - Secrets 配置详细指南
  - 敏感信息安全管理
  - 个人访问令牌生成
  - Workflow 中使用 Secrets
  - 安全最佳实践
  - 预计阅读时间: 20分钟

### 🔍 参考文档

**了解项目架构和组织结构:**

- **[STRUCTURE.md](STRUCTURE.md)** - 项目结构详细说明
  - 目录结构和文件用途
  - 配置文件说明
  - 数据持久化机制
  - 预计阅读时间: 10分钟

### ❓ 帮助与支持

**遇到问题? 查看这些文档:**

- **[FAQ.md](FAQ.md)** - 常见问题解答
  - 部署问题
  - 访问和配置问题
  - CI/CD 问题
  - 镜像仓库问题
  - 性能优化建议
  - 快速查找答案

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 系统性故障排查指南
  - 诊断工具使用
  - 常见故障模式
  - 日志分析方法
  - 性能问题排查
  - 深度调试技巧

### 💡 示例文件

**参考这些示例快速上手:**

- **[examples/workflows/](examples/workflows/)** - Workflow 示例集合
  - `basic-test.yml` - 基础测试 workflow
  - `build-and-push.yml` - Docker 镜像构建和推送
  - `advanced-cicd.yml` - 高级 CI/CD 流程

---

## 🗺️ 学习路径推荐

### 路径1: 新用户快速部署

```
1. QUICKSTART.md (必读)
   ↓
2. 访问 Gitea 并创建第一个仓库
   ↓
3. FAQ.md (遇到问题时查阅)
```

### 路径2: 启用 CI/CD 功能

```
1. QUICKSTART.md (确保平台正常运行)
   ↓
2. CICD_GUIDE.md (配置 Runner 和 Actions)
   ↓
3. examples/workflows/ (参考示例)
   ↓
4. SECRETS_GUIDE.md (配置敏感信息)
   ↓
5. FAQ.md → CI/CD 相关问题
```

### 路径3: 深入了解架构

```
1. STRUCTURE.md (理解项目组织)
   ↓
2. CICD_GUIDE.md (了解 CI/CD 工作原理)
   ↓
3. TROUBLESHOOTING.md (掌握调试技巧)
```

---

## 📝 文档约定

### 符号说明

- ✅ - 推荐做法
- ❌ - 不推荐做法
- ⚠️ - 注意事项
- 💡 - 提示和技巧
- 🔧 - 操作步骤

### 命令标识

- `代码块` - 需要执行的命令或配置
- **粗体** - 重要概念或UI元素
- *斜体* - 变量或需要替换的内容

---

## 🔗 外部资源

### 官方文档

- [Gitea 官方文档](https://docs.gitea.io/)
- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [GitHub Actions 文档](https://docs.github.com/en/actions) (Gitea Actions 兼容)

### 社区资源

- [Gitea Discourse 论坛](https://discourse.gitea.io/)
- [Gitea GitHub 仓库](https://github.com/go-gitea/gitea)

---

## 📮 反馈与贡献

如果您在文档中发现错误或有改进建议,欢迎:

- 提交 Issue
- 发起 Pull Request
- 分享您的使用经验

---

**提示**: 建议将本文档添加到浏览器书签,方便随时查阅。
