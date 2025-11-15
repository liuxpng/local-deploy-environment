# Gitea Dockerfile
FROM gitea/gitea:latest

# 设置时区
ENV TZ=Asia/Shanghai

# 复制自定义配置文件（可选，也可以通过环境变量配置）
# 如果使用此配置文件，需要在 docker-compose.yml 中挂载
# COPY app.ini /etc/gitea/app.ini

# 暴露端口
EXPOSE 3000 22

# 注意：不覆盖基础镜像的 ENTRYPOINT 和 CMD
