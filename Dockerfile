# ========================================================================
# 第一阶段：构建阶段
# ========================================================================
# 使用 Node.js 20 官方镜像作为基础镜像（支持多平台构建）
FROM --platform=${TARGETPLATFORM} node:20 AS builder

# 全局安装 pnpm 包管理器（指定版本 9）
RUN npm install -g pnpm@9

# 设置工作目录为 /app
WORKDIR /app

# 复制项目依赖定义文件（利用 Docker 层缓存优化）
# 这些文件变更频率较低，优先复制可提高构建效率
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/core/package.json ./apps/core/
COPY apps/electron/package.json ./apps/electron/
COPY apps/mobile/package.json ./apps/mobile/
COPY packages/fs/package.json ./packages/fs/
COPY packages/jit/package.json ./packages/jit/
COPY packages/server/package.json ./packages/server/

# 安装项目依赖（使用 --frozen-lockfile 确保依赖版本一致性）
RUN pnpm install --frozen-lockfile

# 复制全部源代码（在依赖安装后复制，避免代码变更导致依赖重装）
COPY . .

# 构建核心应用（完整模式）
RUN pnpm build:full

# 构建文件服务器包
RUN cd packages/fs && pnpm build

# ========================================================================
# 第二阶段：运行阶段
# ========================================================================
# 使用轻量级 Alpine 版 Node.js 20 镜像（减小最终镜像体积）
FROM --platform=${TARGETPLATFORM} node:20-alpine

# 设置生产环境变量
ENV NODE_ENV=production

# 全局安装 PM2 进程管理器
RUN npm install -g pm2

# 设置工作目录
WORKDIR /app

# 从构建阶段复制核心应用产物
COPY --from=builder /app/apps/core/dist ./

# 从构建阶段复制文件服务器产物
COPY --from=builder /app/packages/fs/dist ./packages/fs/dist
COPY --from=builder /app/packages/fs/package.json ./packages/fs/package.json

# 复制并重命名游戏大厅服务器（.js 改为 .cjs 以兼容 CommonJS）
COPY --from=builder /app/server.js ./server.cjs

# 复制配置文件
COPY process.yml ./
COPY http-server.js ./

# 创建运行时 package.json（启用 ES 模块支持）
RUN echo '{"type": "module"}' > package.json

# 安装运行时核心依赖（精简版，不包含开发依赖）
RUN npm install --omit=dev \
  fastify \
  ws@1.0.1 \
  @fastify/cors \
  @fastify/static \
  minimist \
  vue@^3.5.27 \
  express@4.18.2 options@0.0.6 ultron@1.0.2 undici-types@5.26.5 @types/node@20.10.6

# 创建 Vue 符号链接（兼容 importmap）
# 优先尝试生产版本，失败则回退到开发版本
RUN ln -s node_modules/vue/dist/vue.esm-browser.prod.js vue.js || \
    ln -s node_modules/vue/dist/vue.esm-browser.js vue.js

# 调试：打印目录结构（生产环境可移除）
RUN echo "=== 检查 /app/src ===" && \
    ls -la /app/src || echo "src 目录不存在" && \
    echo "=== 检查 /app 根目录 ===" && \
    ls -la /app/

# 暴露服务端口（HTTP 和 WebSocket）
EXPOSE 80 8080

# 使用 PM2 启动应用（根据 process.yml 配置）
CMD ["pm2-runtime", "process.yml"]
