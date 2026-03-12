#!/bin/bash
# 资讯监控系统 - 定时更新脚本
# 用于 crontab 定时任务调用

set -e

# 项目路径（请根据实际情况修改）
PROJECT_DIR="/path/to/news-monitor"

# 日志文件路径
LOG_FILE="${PROJECT_DIR}/cron_update.log"

# 切换到项目目录
cd "$PROJECT_DIR"

# 记录开始时间
echo "" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始更新新闻数据" >> "$LOG_FILE"

# 方法 1: Docker 方式执行（推荐）
# 通过 docker exec 在容器内执行爬虫脚本
docker exec news-monitor-app python run_crawlers.py >> "$LOG_FILE" 2>&1

# 方法 2: 如果是本地运行（非 Docker），取消下面这行的注释
# python3 run_crawlers.py >> "$LOG_FILE" 2>&1

# 记录结束时间
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 更新完成" >> "$LOG_FILE"
