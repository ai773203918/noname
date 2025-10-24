FROM node:20-alpine

# ENV NODE_ENV=production
# ENV PNPM_HOME=/usr/local/share/pnpm
# ENV PATH=$PNPM_HOME:$PATH

# 安装 pnpm（比 npm 更节省空间和依赖）
RUN npm install -g pnpm@8 && npm cache clean --force

WORKDIR /app

# 复制文件
COPY . .

# 使用 pnpm 安装依赖（pnpm 的磁盘使用效率更高）
RUN pnpm install --prod --frozen-lockfile && \
    pnpm store prune && \
    rm -rf ~/.pnpm-store

# 安装 pm2（放在依赖安装之后，利用分层缓存）
RUN pnpm add -g pm2 && \
    pnpm cache clean --force

# 清理不必要的文件
RUN rm -rf /tmp/* /var/tmp/* && \
    rm -rf /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/man && \
    find /usr/local/lib/node_modules -name "*.md" -delete -o -name "*.ts" -delete -o -name "*.map" -delete

EXPOSE 80 8080

CMD ["pm2-runtime", "process.yml"]
