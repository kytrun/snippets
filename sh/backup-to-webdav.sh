#!/bin/bash

# WebDAV服务器配置
WEBDAV_URL="https://webdav_server/dav/"
WEBDAV_USER="webdav_account"
WEBDAV_PASS="webdav_password"

# 创建临时文件存储curl输出
TEMP_FILE=$(mktemp)

# 获取今天是星期几（0-6，0代表星期天）
WEEKDAY=$(date +%u)
WEEKDAY_SUFFIX="_$WEEKDAY"

# 创建WebDAV目录的函数
create_webdav_directory() {
    local dir_path="$1"

    echo "正在创建WebDAV目录: $dir_path"

    # 使用curl创建目录
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" \
         -X MKCOL "$WEBDAV_URL$dir_path" \
         2>&1 > "$TEMP_FILE"

    # 检查目录创建是否成功
    if [ $? -eq 0 ]; then
        echo "✓ 目录创建成功: $dir_path"
    else
        echo "✗ 目录创建失败: $dir_path"
        echo "错误信息: $(cat "$TEMP_FILE")"
    fi
}

# 上传单个文件的函数
upload_file() {
    local file="$1"
    local remote_path="$2"

    echo "正在上传: $remote_path"

    # 使用curl上传文件到WebDAV
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" \
         -T "$file" \
         "$WEBDAV_URL$remote_path" \
         2>&1 > "$TEMP_FILE"

    # 检查上传是否成功
    if [ $? -eq 0 ]; then
        echo "✓ 上传成功: $remote_path"
    else
        echo "✗ 上传失败: $remote_path"
        echo "错误信息: $(cat "$TEMP_FILE")"
    fi
}

# 处理单个路径
process_path() {
    local LOCAL_PATH="$1"
    echo "开始处理: $LOCAL_PATH"

    # 检查是文件还是目录
    if [ -f "$LOCAL_PATH" ]; then
        # 如果是文件，直接上传
        FILENAME=$(basename "$LOCAL_PATH")
        DIRNAME=$(dirname "$LOCAL_PATH")
        DIRNAME=$(echo "$DIRNAME" | sed 's/^\///' | sed 's/\//_/g')
        REMOTE_DIR="$DIRNAME$WEEKDAY_SUFFIX"
        REMOTE_PATH="$REMOTE_DIR/$FILENAME"

        # 创建WebDAV目录
        create_webdav_directory "$REMOTE_DIR/"

        # 上传文件
        upload_file "$LOCAL_PATH" "$REMOTE_PATH"
    elif [ -d "$LOCAL_PATH" ]; then
        # 上传目录中的所有文件，将路径转换为下划线
        find "$LOCAL_PATH" -type f | while read file; do
            # 获取文件的原始目录
            DIRNAME=$(dirname "$file")
            DIRNAME=$(echo "$DIRNAME" | sed 's/^\///' | sed 's/\//_/g')
            # 获取文件名
            FILENAME=$(basename "$file")
            # 创建远程目录路径
            REMOTE_DIR="$DIRNAME$WEEKDAY_SUFFIX"
            REMOTE_PATH="$REMOTE_DIR/$FILENAME"

            # 创建WebDAV目录
            create_webdav_directory "$REMOTE_DIR/"

            # 上传文件
            upload_file "$file" "$REMOTE_PATH"
        done
    else
        echo "警告: $LOCAL_PATH 不存在或无法访问"
    fi
}

# 处理命令行参数
if [ $# -eq 0 ]; then
    echo "用法: $0 文件或目录路径 [文件或目录路径 ...]"
    exit 1
fi

# 遍历所有命令行参数
for path in "$@"; do
    process_path "$path"
done

# 清理临时文件
rm -f "$TEMP_FILE"
