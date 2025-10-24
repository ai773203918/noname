FROM node:20-alpine

# ENV NODE_ENV=production
# ENV PNPM_HOME=/usr/local/share/pnpm
# ENV PATH=$PNPM_HOME:$PATH

WORKDIR /app

# 复制文件
COPY . .

# 使用 npm 安装生产依赖
RUN npm install --omit=dev express@4.18.2 minimist ws

# 直接使用 npm，避免 pnpm 兼容性问题
RUN npm install -g pm2

# 清理不必要的文件
RUN rm -rf /tmp/* /var/tmp/* && \
    rm -rf /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/man && \
    rm -rf noname-server.exe .git .github README.md Dockerfile .gitignore .dockerignore && \
    find /usr/local/lib/node_modules -name "*.md" -delete -o -name "*.ts" -delete -o -name "*.map" -delete

EXPOSE 80 8080

CMD ["pm2-runtime", "process.yml"]
