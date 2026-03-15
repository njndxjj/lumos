#!/bin/bash
# 阿里云 ECS 一键部署脚本
# 使用方法：在阿里云 ECS 上运行 bash deploy_alibaba_cloud.sh

set -e

echo "========================================"
echo "  阿里云 ECS 部署脚本 - Lumos 新闻爬虫"
echo "========================================"

# 1. 安装 Docker
echo "正在安装 Docker..."
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
systemctl enable docker
systemctl start docker

# 2. 安装 Docker Compose
echo "正在安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 3. 创建应用目录
echo "创建应用目录..."
mkdir -p /opt/lumos/data
cd /opt/lumos

# 4. 下载项目代码（从 GitHub）
echo "克隆项目代码..."
git clone https://github.com/njndxjj/lumos.git . || {
    echo "代码已存在，跳过克隆..."
}

# 5. 创建 Docker Compose 配置文件
echo "创建 Docker Compose 配置..."
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
    devices:
      - /dev/kmsg
    # 健康检查
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/news"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# 6. 创建环境变量文件
echo "创建环境变量配置..."
cat > .env << 'EOF'
# 通义千问 API Key（请替换为你的实际 API Key）
DASHSCOPE_API_KEY=sk-1acde23fddbd4a83bd0aa451a6a60a47

# 飞书 Webhook（可选）
FEISHU_WEBHOOK=https://open.feishu.cn/open-apis/bot/v2/hook/your_webhook_here
EOF

echo ""
echo "⚠️  请编辑 /opt/lumos/.env 文件，配置你的 API Key 和飞书 Webhook"
echo ""

# 7. 构建并启动
echo "构建 Docker 镜像..."
docker-compose build

echo "启动容器..."
docker-compose up -d

# 8. 查看状态
echo ""
echo "========================================"
echo "  部署完成！"
echo "========================================"
echo ""
echo "📊 查看运行状态：docker-compose ps"
echo "📝 查看日志：docker-compose logs -f"
echo "🌐 访问地址：http://$(curl -s http://metadata.tencentyun.com/latest/meta-data/public-ipv4 2>/dev/null || echo '你的服务器 IP'):5000"
echo ""
echo "🔧 常用命令："
echo "  - 重启服务：docker-compose restart"
echo "  - 停止服务：docker-compose down"
echo "  - 更新代码：cd /opt/lumos && git pull && docker-compose up -d --build"
echo ""

# 9. 配置阿里云安全组（提示）
echo "========================================"
echo "  ⚠️ 重要：配置阿里云安全组"
echo "========================================"
echo ""
echo "1. 登录阿里云控制台"
echo "2. 进入 ECS 实例详情页"
echo "3. 点击「安全组」→「配置规则」"
echo "4. 添加入站规则：端口 5000，授权对象 0.0.0.0/0"
echo ""
