# Lumos Docker 部署指南

## 📋 配置说明

### 端口分配
- **前端**: 3000 端口 (`http://IP:3000`)
- **后端**: 5000 端口 (内部访问，不暴露)

### 服务架构
```
┌─────────────────┐
│   Nginx (可选)   │
│    端口 80/443   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼────┐  ┌─▼────────┐
│ 前端    │  │ 后端      │
│ 3000   │  │ 5000     │
│ React  │  │ Flask    │
└────────┘  └──────────┘
```

## 🚀 快速部署

### 1. 上传到服务器

```bash
# 在本地执行
scp -r Lumos root@172.30.82.222:/opt/lumos/
```

### 2. 配置环境变量

在服务器上创建 `.env` 文件：

```bash
cd /opt/lumos/Lumos
cat > .env << EOF
# 通义千问 API Key
DASHSCOPE_API_KEY=your-api-key

# 飞书 Webhook
FEISHU_WEBHOOK=your-webhook-url

# 浏览器搜索 (可选)
BROWSER_SEARCH_ENABLED=true

# AI 分析源
AI_ANALYSIS_SOURCE=browser
EOF
```

### 3. 启动服务

```bash
# 停止并清理旧容器（如果有）
docker-compose down

# 构建并启动
docker-compose up -d --build

# 查看日志
docker-compose logs -f
```

### 4. 验证部署

```bash
# 检查容器状态
docker-compose ps

# 测试后端健康检查
curl http://localhost:5000/api/health

# 测试前端
curl http://localhost:3000
```

## 🔧 服务管理

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看后端日志
docker-compose logs -f backend

# 查看前端日志
docker-compose logs -f frontend
```

### 重启服务
```bash
# 重启所有服务
docker-compose restart

# 重启单个服务
docker-compose restart backend
docker-compose restart frontend
```

### 停止服务
```bash
docker-compose down
```

### 更新部署
```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build
```

## 📝 数据持久化

以下数据通过 Docker Volume 持久化：
- `database.sqlite3` - 数据库
- `config/` - 配置文件
- `logs/` - 日志文件

这些文件在宿主机上，容器删除后数据不丢失。

## 🔐 Nginx 反向代理（可选）

如果需要域名访问和 HTTPS，配置 Nginx：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 前端
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 后端 API
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## ⚠️ 常见问题

### 1. 端口被占用
如果 3000 端口被占用，修改 `docker-compose.yml`：
```yaml
ports:
  - "8080:3000"  # 改为 8080 或其他端口
```

### 2. 后端连接失败
检查后端健康状态：
```bash
docker-compose exec backend curl http://localhost:5000/api/health
```

### 3. 数据库权限问题
```bash
# 确保数据库文件有读写权限
chmod 666 /opt/lumos/Lumos/database.sqlite3
```

### 4. 前端无法连接后端
- 前端通过 `server.js` 代理 `/api` 请求到 `http://localhost:5000`
- 在 Docker 网络中，需要通过服务名访问：`http://backend:5000`
- 查看 `frontend-new/server.js` 的代理配置

## 📊 监控和运维

### 查看容器资源占用
```bash
docker stats lumos-backend lumos-frontend
```

### 进入容器调试
```bash
# 进入后端容器
docker-compose exec backend bash

# 进入前端容器
docker-compose exec frontend bash
```

### 备份数据库
```bash
cp /opt/lumos/Lumos/database.sqlite3 /opt/lumos/Lumos/database.sqlite3.backup.$(date +%Y%m%d)
```

## 🎯 访问地址

部署成功后：
- **前端访问**: `http://172.30.82.222:3000`
- **后端 API**: `http://172.30.82.222:3000/api/*`
- **定时任务**: 每 10 分钟自动执行

---

**提示**:
- 首次启动需要 2-3 分钟构建镜像
- 确保服务器防火墙开放 3000 端口
- 生产环境建议使用 Nginx + HTTPS
