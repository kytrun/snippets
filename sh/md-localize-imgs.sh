#!/bin/bash

# 检查参数是否为空
if [ -z "$1" ]; then
  echo "请指定 Markdown 文件路径作为参数"
  exit 1
fi

# 提取文件名和目录路径
filepath="$1"
dirname=$(dirname "$filepath")
filename=$(basename "$filepath")
extension="${filename##*.}"
filename="${filename%.*}"

# 创建图片存放目录
assets_dir="${dirname}/${filename}.assets"
mkdir -p "$assets_dir"

# 匹配 Markdown 文件中的图片链接，并下载图片
image_urls=$(grep -oE '!\[.*\]\((http|https)://[^)]+\)' "$filepath" | sed -E 's/^!\[.*\]\((http|https):\/\/([^)]+)\)$/\1:\/\/\2/g')

for url in $image_urls; do
  # 提取文件名和扩展名
  image_filename=$(basename "$url")
  image_extension="${image_filename##*.}"

  # 添加随机数
  image_filename="${image_filename%.*}_${RANDOM}.${image_extension}"

  # 替换特殊字符为下划线
  image_filename=$(echo "$image_filename" | sed 's/["&:<>*?\\\/|]/_/g')

  # 拼接本地文件路径
  local_filepath="${assets_dir}/${image_filename}"

  # 下载图片
  echo "正在下载图片：$url"
  curl -o "$local_filepath" "$url"

  # 替换 Markdown 文件中的图片链接
  sed -i "s|($url)|(./${filename}.assets/${image_filename})|g" "$filepath"
done

echo "图片下载和链接替换完成。"
