#!/bin/bash
# ================================================
# 好物推荐页 - GitHub Pages 一键部署脚本
# ================================================
# 使用方式:
#   方式1: 给予 GitHub Token 自动创建仓库并部署
#     ./deploy.sh --token ghp_xxxxxxxxxxxx
#
#   方式2: 只初始化本地仓库，手动推送到 GitHub
#     ./deploy.sh
#
#   方式3: 推送到已有仓库
#     ./deploy.sh --repo git@github.com:你的用户名/goods-recommend.git

set -e

GOODS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$GOODS_DIR"

echo "========================================="
echo "  好物推荐页 - GitHub Pages 部署工具"
echo "========================================="
echo ""

# 如果 index.html 不存在，提示
if [ ! -f "index.html" ]; then
  echo "❌ 未找到 index.html，请先创建页面"
  exit 1
fi

# 如果已经有 git 仓库
if [ ! -d ".git" ]; then
  git init
  git add index.html
  git commit -m "init: 好物推荐页 $(date +%Y-%m-%d)"
  echo "✅ 本地仓库已初始化"
fi

# 检查参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --repo)
      REMOTE="$2"
      shift 2
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

# 方案1: 有 token，自动创建仓库并部署
if [ -n "$TOKEN" ]; then
  USERNAME=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))")
  if [ -z "$USERNAME" ]; then
    echo "❌ Token 无效，请检查"
    exit 1
  fi
  echo "✅ GitHub 用户: $USERNAME"

  # 创建仓库
  echo "⏳ 创建 GitHub 仓库..."
  CREATE_RESULT=$(curl -s -X POST -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    https://api.github.com/user/repos \
    -d '{"name":"goods-recommend","description":"好物推荐页 - 精选好物推荐","homepage":"https://'$USERNAME'.github.io/goods-recommend/","auto_init":false,"license":"mit"}')
  
  REPO_URL=$(echo "$CREATE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('clone_url',''))")
  
  if [ -z "$REPO_URL" ]; then
    echo "❌ 仓库创建失败: $(echo "$CREATE_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','unknown'))")"
    exit 1
  fi
  echo "✅ 仓库已创建: $REPO_URL"

  # 配置 remote 并推送
  git remote remove origin 2>/dev/null || true
  git remote add origin "$REPO_URL"
  git branch -M main
  git push -u origin main
  
  # 创建 gh-pages 分支（也可以直接用 main 分支配合 docs/ 目录）
  git checkout -b gh-pages 2>/dev/null || git branch -D gh-pages && git checkout -b gh-pages
  git push -u origin gh-pages --force
  
  # 切回 main
  git checkout main

  # 启用 GitHub Pages（需要先创建 gh-pages 分支再等几分钟生效）
  echo "⏳ 启用 GitHub Pages..."
  curl -s -X POST -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/$USERNAME/goods-recommend/pages" \
    -d '{"source":{"branch":"gh-pages","path":"/"}}' 2>&1 || echo "  提示：Pages 可能需要手动在 GitHub 仓库 Settings → Pages 中启用"

  echo ""
  echo "========================================="
  echo "  🎉 部署完成！"
  echo "========================================="
  echo ""
  echo "  访问地址: https://$USERNAME.github.io/goods-recommend/"
  echo "  仓库地址: https://github.com/$USERNAME/goods-recommend"
  echo ""
  echo "  下一步：把这个链接贴到你"
  echo "  的小红书个人简介里！"
  echo ""
  echo "========================================="
  exit 0
fi

# 方案2: 有自定义 remote
if [ -n "$REMOTE" ]; then
  git remote remove origin 2>/dev/null || true
  git remote add origin "$REMOTE"
  git branch -M main
  git push -u origin main
  echo "✅ 已推送到: $REMOTE"
  echo ""
  echo "记得在 GitHub 仓库 Settings → Pages 中启用 GitHub Pages"
  exit 0
fi

# 方案3: 无参数 - 只显示指引
echo ""
echo "========================================="
echo "  📋 手动部署指引"
echo "========================================="
echo ""
echo "  方式一（推荐，需要 GitHub Token）："
echo "    ./deploy.sh --token ghp_xxxxxxxxxxxx"
echo ""
echo "  方式二（手动推送）："
echo ""
echo "  ① 打开 https://github.com/new"
echo "  ② 仓库名填写: goods-recommend"
echo "  ③ 选择 Public，不勾选任何选项"
echo "  ④ 点击 Create repository"
echo "  ⑤ 执行:"
echo ""
echo "     git remote add origin git@github.com:你的用户名/goods-recommend.git"
echo "     git branch -M main"
echo "     git push -u origin main"
echo ""
echo "  ⑥ 在仓库 Settings → Pages 中："
echo "     - Branch 选 main, / (root)"
echo "     - 点 Save"
echo ""
echo "  ⑦ 等待2分钟即可访问:"
echo "     https://你的用户名.github.io/goods-recommend/"
echo ""
echo "========================================="
echo ""
echo "  💡 获取 GitHub Token："
echo "     https://github.com/settings/tokens"
echo "     创建 Token → 勾选 repo 权限"
echo ""
echo "========================================="
