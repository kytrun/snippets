#!/bin/bash
# 找到最大版本号的 jar 文件

# 进入脚本所在目录
directory=`dirname $0`
cd $directory

latestJarName=$(ls -1 *.jar | \
    awk -F- '{print $2 " " $0}' | \
    sort -t. -n -r -k1,3 | \
    awk 'NR == 1 {print $2}')
echo $latestJarName
