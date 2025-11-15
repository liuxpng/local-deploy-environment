# Traefik Dockerfile
FROM traefik:v3.0

# 创建日志目录
RUN mkdir -p /var/log/traefik

# 复制配置文件
COPY traefik.yml /etc/traefik/traefik.yml
COPY dynamic /etc/traefik/dynamic

# 暴露端口
EXPOSE 80 443 8080
