#!/bin/bash
# ================================================
# 好物推荐页自动更新脚本
# 由 cron 每天调用，自动搜品并推送更新
# ================================================
set -e

# 加载配置
source /Users/liuzhupeng/.openclaw/workspace/skills/taobao-affiliate/secret.sh

GOODS_DIR="/Users/liuzhupeng/workspace/goods-recommend"
MAISHOU_DIR="/Users/liuzhupeng/.openclaw/workspace/.agents/skills/maishou/scripts"
PID="$PID"
DATE=$(date +%Y-%m-%d)

cd "$GOODS_DIR"

# 1. 删除旧页
rm -f index.html

# 2. 这个步骤由 cron 的 agentTurn 完成（AI 搜品+写HTML）
# 脚本只负责推送，不负责生成内容
# 内容索引文件描述本次推荐的商品
touch ".update-${DATE}"
echo "等待 cron AI 生成 index.html..."
