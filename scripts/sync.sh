#!/bin/bash

# 自动提交并包含日期的 Git 脚本

# 获取当前日期（格式：YYYY-MM-DD）
current_date=$(date +%Y-%m-%d)

# 拉取最新代码
echo "正在拉取最新代码..."
git pull origin main

# 添加所有更改
echo "正在添加所有更改..."
git add .

# 检查是否有文件需要提交
if [ -z "$(git status --porcelain)" ]; then
    echo "没有更改需要提交"
    exit 0
fi

# 提交更改并使用当前日期作为提交信息
echo "正在提交更改..."
git commit -m "$current_date"

# 推送代码到远程仓库
echo "正在推送到远程仓库..."
git push origin main

echo "操作完成！最新提交日期：$current_date"    