# PostgreSQL Dockerfile
FROM postgres:15.15-alpine3.21

# 设置时区
ENV TZ=Asia/Shanghai

# 安装必要的工具
RUN apk add --no-cache tzdata

# 复制初始化脚本
COPY init.sql /docker-entrypoint-initdb.d/

# 暴露端口
EXPOSE 5432
