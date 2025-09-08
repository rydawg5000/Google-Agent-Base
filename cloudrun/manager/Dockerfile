# Node LTS
FROM node:22-alpine
WORKDIR /app
COPY server.js package*.json ./
RUN npm ci --omit=dev
EXPOSE 8080
CMD ["node", "server.js"]
