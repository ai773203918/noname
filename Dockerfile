FROM --platform=${TARGETPLATFORM} node:20-alpine

ENV NODE_ENV=production

RUN npm install -g pm2

WORKDIR /app

COPY . .

RUN npm install --omit=dev express@4.18.2 minimist ws@1.0.1 options@0.0.6 ultron@1.0.2 undici-types@5.26.5 @types/node@20.10.6

RUN rm -rf noname-server.exe .git .github README.md Dockerfile .gitignore .dockerignore

EXPOSE 80 8080

CMD ["pm2-runtime", "process.yml"]
