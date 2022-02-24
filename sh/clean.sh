#!/bin/sh
# 清理文件（夹）
source /etc/profile
find /temp-file/ -mtime +1 -name "*" | xargs rm -rf