#!/bin/bash
# @Desc 此脚本用于获取一个指定区间且未被占用的随机端口号
# @Author Hellxz <hellxz001@foxmail.com>

PORT=0
#判断当前端口是否被占用，没被占用返回0，反之1
function checkPort {
   existPort=`/usr/sbin/lsof -i :$1|grep -v "PID" | awk '{print $2}'`
   if [ "$existPort" != "" ]; then
      echo "1"
   else
      echo "0"
   fi
}

#指定区间随机数
function randomRange {
   shuf -i $1-$2 -n1
}

#得到随机端口
function getRandomPort {
   temp1=0
   while [ $PORT == 0 ]; do
       temp1=`randomRange $1 $2`
       if [ `checkPort $temp1` == 0 ] ; then
              PORT=$temp1
       else
         getRandomPort $1 $2
       fi
   done
   echo "port=$PORT"
}
get_random_port 1 10000; #这里指定了1~10000区间，从中任取一个未占用端口号
