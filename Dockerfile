# 使用轻量级 Alpine 版 Node.js 20 镜像（减小最终镜像体积）
FROM --platform=${TARGETPLATFORM} node:20-alpine

# 设置生产环境变量
ENV NODE_ENV=production

# 全局安装 pnpm 包管理器（指定版本 9）
RUN npm install -g pnpm@9

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 安装依赖
RUN pnpm install

# 暴露服务端口（HTTP 和 WebSocket）
EXPOSE 80

# 使用 PM2 启动应用（根据 process.yml 配置）
CMD ["pnpm", "dev"]
