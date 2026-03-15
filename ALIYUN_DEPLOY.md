# 阿里云部署指南

## 🚀 快速开始

### 第一步：购买阿里云 ECS

**推荐配置**（经济型）：
- **实例规格**：2 核 4G（突发性能型 t5/t6）
- **操作系统**：Ubuntu 22.04 或 CentOS 7.9
- **带宽**：3-5Mbps
- **存储**：40GB SSD
- **价格**：约 ¥300-500/年

**购买链接**：https://www.aliyun.com/product/ecs

### 第二步：配置安全组

登录阿里云控制台，添加安全组规则：

| 规则方向 | 优先级 | 策略 | 协议类型 | 端口范围 | 授权对象 |
|----------|--------|------|----------|----------|----------|
| 入方向 | 1 | 允许 | TCP | 5000/5000 | 0.0.0.0/0 |
| 入方向 | 1 | 允许 | TCP | 22/22 | 0.0.0.0/0 |

### 第三步：SSH 连接服务器

```bash
# macOS / Linux
ssh root@你的服务器 IP

# Windows 使用 PuTTY 或 Xshell
```

### 第四步：一键部署

**方式一：自动脚本（推荐）**

```bash
# 1. 下载安装脚本
cd /root
curl -O https://raw.githubusercontent.com/njndxjj/lumos/main/deploy_alibaba_cloud.sh
chmod +x deploy_alibaba_cloud.sh

# 2. 运行脚本
bash deploy_alibaba_cloud.sh
```

**方式二：手动部署**

```bash
# 1. 安装 Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
systemctl enable docker && systemctl start docker

# 2. 安装 Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 3. 克隆项目
cd /opt
git clone https://github.com/njndxjj/lumos.git
cd lumos

# 4. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入你的 DASHSCOPE_API_KEY 和 FEISHU_WEBHOOK

# 5. 构建并启动
docker-compose build
docker-compose up -d

# 6. 查看状态
docker-compose ps
```

### 第五步：验证部署

```bash
# 查看运行日志
docker-compose logs -f

# 测试访问
curl http://localhost:5000/api/news

# 浏览器访问
http://你的服务器 IP:5000
```

---

## 📋 配置说明

### 环境变量配置

编辑 `/opt/lumos/.env` 文件：

```bash
# 通义千问 API Key
DASHSCOPE_API_KEY=sk-1acde23fddbd4a83bd0aa451a6a60a47

# 飞书 Webhook
FEISHU_WEBHOOK=https://open.feishu.cn/open-apis/bot/v2/hook/your_webhook_here

# 启用浏览器搜索（支持本地代理）
BROWSER_SEARCH_ENABLED=true
```

### 定时任务配置

已配置每 10 分钟自动执行爬虫：

```bash
# 查看定时任务日志
docker-compose logs | grep "爬虫执行完成"

# 手动执行一次
docker-compose exec lumos python run_crawlers.py
```

### 数据持久化

- **数据库位置**：`/opt/lumos/data/news.db`
- **浏览器缓存**：`/ms-playwright`（挂载到宿主机）

---

## 🔧 运维管理

### 常用命令

```bash
# 进入容器
docker-compose exec lumos bash

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 更新代码
cd /opt/lumos
git pull
docker-compose up -d --build

# 查看日志
docker-compose logs -f

# 查看资源占用
docker stats lumos
```

### 日志管理

```bash
# 查看最近 100 行日志
docker-compose logs --tail=100

# 导出日志
docker-compose logs > lumos.log

# 清理旧日志
docker-compose logs --since=24h
```

### 备份数据库

```bash
# 备份
cp /opt/lumos/data/news.db /opt/lumos/data/news.db.backup.$(date +%Y%m%d)

# 恢复
cp /opt/lumos/data/news.db.backup.YYYYMMDD /opt/lumos/data/news.db
```

---

## 📊 费用预估

**阿里云 ECS 经济型配置**：

| 项目 | 配置 | 价格 |
|------|------|------|
| ECS 实例 | 2 核 4G 60GB | ¥365/年 |
| 带宽 | 3Mbps | 包含在实例中 |
| 存储 | 60GB SSD | 包含在实例中 |
| **总计** | | **约 ¥365/年** |

---

## 🎯 优势对比

| 特性 | Railway | 阿里云 ECS |
|------|---------|-----------|
| 浏览器代理 | ❌ 不支持 | ✅ 支持 |
| 定时任务 | ✅ 支持 | ✅ 支持 |
| 数据持久化 | ⚠️ 需配置 | ✅ 原生支持 |
| 公网访问 | ✅ 自动分配 | ✅ 固定 IP |
| 成本 | $5-10/月 | ¥30/月 |
| 上手难度 | ⭐ 简单 | ⭐⭐ 中等 |
| 灵活性 | ⭐⭐ 一般 | ⭐⭐⭐⭐ 高 |

---

## 🆘 常见问题

### 1. 无法访问 Web 界面

**检查安全组配置**：确保端口 5000 已开放

```bash
# 测试端口监听
netstat -tlnp | grep 5000
```

### 2. 爬虫执行失败

**检查浏览器依赖**：

```bash
docker-compose exec lumos playwright install chromium
```

### 3. 数据库锁定

**重启服务**：

```bash
docker-compose restart
```

### 4. 内存不足

**添加 Swap**：

```bash
# 创建 2GB Swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## 📞 技术支持

遇到问题？查看完整日志：

```bash
docker-compose logs > error.log
```

把日志内容发给我，我帮你解决！
