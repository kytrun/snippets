#!/bin/bash
# 不停机更新服务
if [ $# == 0 ];then
   echo "No service version specified"
	exit 1
else
	echo "Service version: $1"
fi

# 定义变量
SERVICE_NAME="service-name"
# jar版本
JAR_VER=$1
JAR_NAME="${SERVICE_NAME}-${JAR_VER}.jar"

# 不存在版本的文件提示
if [ ! -f "$JAR_NAME" ];then
   echo "${JAR_NAME} 不存在"
	exit 1
fi

# 日志路径，加不加引号都行。 注意：等号两边 不能 有空格，否则会提示command找不到
LOG_PATH="/deploy/service-name/log/${SERVICE_NAME}-service/info.log"
# 端口范围
MIN_PORT=8000
MAX_PORT=8500

# @Desc 此脚本用于获取一个指定区间且未被占用的随机端口号
# @Author Hellxz <hellxz001@foxmail.com>

# 判断当前端口是否被占用，没被占用返回0，反之1
function checkPort {
   existPort=`/usr/sbin/lsof -i :$1|grep -v "PID" | awk '{print $2}'`
   if [ "$existPort" != "" ]; then
      echo "1"
   else
      echo "0"
   fi
}

# 指定区间随机数
function randomRange {
   shuf -i $1-$2 -n1
}

# 获取随机端口
function getRandomPort {
   temp1=0
   while [ $temp1 == 0 ]; do
       temp1=`randomRange $1 $2`
       if [ `checkPort $temp1` == 0 ] ; then
			echo $temp1
       else
         getRandomPort $1 $2
       fi
   done
}


# 启动方法
function startNew {
      # 指定端口
      nohup java -Xmx1g -Xms1g -XX:ParallelGCThreads=2 -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:CICompilerCount=2 -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:MaxDirectMemorySize=256m -XX:NativeMemoryTracking=detail -XX:+UnlockDiagnosticVMOptions -XX:+PrintNMTStatistics -jar -Dspring.profiles.active=prod -Dserver.port=$1 $JAR_NAME > /dev/null &
      # 查出使用当前端口的新进程的 pid
      pid=`ps -ef | grep java | grep $JAR_NAME | grep $1 | grep -v grep | awk '{print $2}'`
      if [ "$pid" == "" ]; then
        echo "Start failed."
        exit 1
      fi
		echo ""
      echo "Service ${JAR_NAME} is starting！pid=${pid}"
		echo "........................Here is the log.............................."
		echo "....................................................................."
      timeout 20 tail -f $LOG_PATH
		echo "........................Start successfully！........................."
}


# 旧实例的pid
OLD_PID=`ps -ef | grep java | grep $SERVICE_NAME | grep -v grep | awk '{print $2}'`
# 旧实例的端口
OLD_PORT=`netstat -anopt |grep $OLD_PID |grep LISTEN|awk '{print $4}'|rev|cut -d: -f 1|grep -E '^[0-9]{4}'|rev`
# 启动新实例
startNew $(getRandomPort $MIN_PORT $MAX_PORT)

# 本机 IP
MACHINE_PHYSICS_NET=$(ls /sys/class/net/ | grep -v "`ls /sys/devices/virtual/net/`")
LOCAL_IP=$(ip addr | grep "$MACHINE_PHYSICS_NET" | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
# 通知 nacos 下线实例
curl -X PUT "127.0.0.1:8848/nacos/v1/ns/instance?serviceName=${SERVICE_NAME}&ip=${LOCAL_IP}&port=${OLD_PORT}&enabled=false"

sleep 35
# 停止旧实例
kill $OLD_PID
