# ========================================================================
# 第一阶段：构建阶段
# ========================================================================
# ==================== 构建阶段 ====================
# 使用一个轻量级的、包含 Node.js 的基础镜像
# 注意：这个阶段我们只针对一个平台构建，比如 linux/amd64，因为产物是跨平台的
FROM --platform=linux/amd64 node:20-alpine AS builder

WORKDIR /app

# 1. 复制项目依赖定义文件（利用 Docker 层缓存优化）
# 这些文件变更频率较低，优先复制可提高构建效率
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/core/package.json ./apps/core/
COPY apps/electron/package.json ./apps/electron/
COPY apps/mobile/package.json ./apps/mobile/
COPY packages/fs/package.json ./packages/fs/
COPY packages/jit/package.json ./packages/jit/
COPY packages/server/package.json ./packages/server/

# 2. 全局安装 pnpm 包管理器（指定版本 9）
RUN npm install -g pnpm@9

# 3. 安装所有依赖 (利用缓存挂载)
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install

# 4. 复制所有源代码
COPY . .

# 5. 执行构建命令
#    --target esnext --no-clean 会让 tsup 只构建，不清理，为下一步做准备
#    我们只关心构建产物（dist目录），不关心启动服务
RUN pnpm build

# 构建文件服务器包
RUN cd packages/fs && pnpm build

# ========================================================================
# 第二阶段：运行阶段
# ========================================================================

# ==================== 运行阶段 ====================
# 为每个目标平台创建一个独立的运行阶段
# --- amd64 运行阶段 ---
FROM --platform=linux/amd64 node:20-alpine AS runtime-amd64
WORKDIR /app

# 安装 pnpm (生产环境也需要)
RUN npm install -g pnpm@9
# 设置生产环境变量
ENV NODE_ENV=production
# 全局安装 PM2 进程管理器
RUN npm install -g pm2

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
# 修复依赖导致无法联机问题(主要是ws)
# RUN npm install --omit=dev ws fastify @fastify/cors @fastify/static minimist vue@^3.5.27
RUN npm install --omit=dev ws@1.0.1 fastify @fastify/cors @fastify/static minimist vue@^3.5.27

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

# --- arm64 运行阶段 ---
FROM --platform=linux/arm64 node:20-alpine AS runtime-arm64
WORKDIR /app

RUN npm install -g pnpm@9
# 设置生产环境变量
ENV NODE_ENV=production
# 全局安装 PM2 进程管理器
RUN npm install -g pm2

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
# 修复依赖导致无法联机问题(主要是ws)
# RUN npm install --omit=dev ws fastify @fastify/cors @fastify/static minimist vue@^3.5.27
RUN npm install --omit=dev ws@1.0.1 fastify @fastify/cors @fastify/static minimist vue@^3.5.27

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
