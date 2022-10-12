#!/bin/sh
##单引号中使用变量 '"$变量名"'
#1. 将代码块结尾 ```\n\n 替换为 ```CODE_END\n\n
#2. 将代码块开头 ```\n 替换为 ```lang\n
#3. 将 ```CODE_END 替换为 ```
cp "$1" "$1.bak.md"
vi -c ':%s/```\n\n/```CODE_END\r\r/g | :%s/```\n/```'"$2"'\r/g | :%s/```CODE_END/```/g | :wq' "$1"
