#!/bin/bash
# 阿里云 ECS (CentOS 7.9) 一键部署脚本
# 使用方法：bash deploy_centos.sh

set -e

echo "========================================"
echo "  阿里云 ECS 部署 - Lumos 新闻爬虫"
echo "  系统：CentOS 7.9 | 4 核 8G"
echo "========================================"

# 1. 安装 Docker
echo "[1/7] 正在安装 Docker..."
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
echo "✓ Docker 安装完成"

# 2. 安装 Docker Compose
echo "[2/7] 正在安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "✓ Docker Compose 安装完成 ($(docker-compose --version))"

# 3. 安装 Git
echo "[3/7] 正在安装 Git..."
yum install -y git
echo "✓ Git 安装完成"

# 4. 创建应用目录
echo "[4/7] 创建应用目录..."
mkdir -p /opt/lumos/data
mkdir -p /ms-playwright
cd /opt/lumos
echo "✓ 应用目录创建完成：/opt/lumos"

# 5. 下载项目代码
echo "[5/7] 克隆项目代码..."
if [ ! -d "crawlers" ]; then
    git clone https://github.com/njndxjj/lumos.git .
    echo "✓ 代码克隆完成"
else
    echo "✓ 代码已存在，拉取最新代码..."
    git pull
fi

# 6. 创建 Docker Compose 配置（适配 CentOS）
echo "[6/7] 创建 Docker Compose 配置..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  lumos:
    build: .
    container_name: lumos
    restart: always
    ports:
      - "5000:5000"
    volumes:
      - ./data:/app/data
      - /ms-playwright:/ms-playwright
    environment:
      - DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY}
      - FEISHU_WEBHOOK=${FEISHU_WEBHOOK}
      - BROWSER_SEARCH_ENABLED=true
    # 允许容器访问宿主机网络（用于浏览器代理）
    network_mode: "host"
    cap_add:
      - SYS_ADMIN
    # 健康检查
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/news"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
EOF

# 7. 创建环境变量文件
echo "[7/7] 创建环境变量配置..."
cat > .env << 'EOF'
# 通义千问 API Key
DASHSCOPE_API_KEY=sk-1acde23fddbd4a83bd0aa451a6a60a47

# 飞书 Webhook（可选）
FEISHU_WEBHOOK=
EOF

echo ""
echo "✓ 环境变量配置完成：/opt/lumos/.env"

# 8. 构建并启动
echo ""
echo "========================================"
echo "  开始构建镜像（约 3-5 分钟）..."
echo "========================================"
docker-compose build

echo ""
echo "========================================"
echo "  启动服务..."
echo "========================================"
docker-compose up -d

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 查看状态
echo ""
echo "========================================"
echo "  🎉 部署完成！"
echo "========================================"
echo ""
echo "📊 容器状态："
docker-compose ps
echo ""
echo "📝 查看日志：docker-compose logs -f"
echo "🌐 访问地址：http://121.196.161.147:5000"
echo ""
echo "🔧 常用命令："
echo "  - 查看状态：docker-compose ps"
echo "  - 查看日志：docker-compose logs -f"
echo "  - 重启服务：docker-compose restart"
echo "  - 停止服务：docker-compose down"
echo "  - 更新代码：cd /opt/lumos && git pull && docker-compose up -d --build"
echo ""
echo "⚠️ 重要配置："
echo "  1. 编辑 /opt/lumos/.env 配置你的 API Key"
echo "  2. 阿里云安全组开放端口 5000"
echo ""
echo "========================================"
