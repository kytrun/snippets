#!/bin/sh
# 进入当前脚本的绝对路径，获取文件夹下所有文件
# 取文件最大版本作为最新版本启动
# 例如：目录下有多个版本的jar包test-0.0.1.jar  test-0.0.2.jar  test-0.0.3.jar 
# 根据循环遍历对比取test-0.0.3.jar作为最新版本启动
directory=`dirname $0`
cd $directory
# 设置JVM运行参数
JVM="-server -Xms256m -Xmx512m -XX:PermSize=64M -XX:MaxNewSize=128m -XX:MaxPermSize=128m -Djava.awt.headless=true -XX:+CMSClassUnloadingEnabled -XX:+CMSPermGenSweepingEnabled"
# 需要指定外部配置文件时，设置该参数
OUTSIDE_PROFILE="--spring.config.additional-location=F:/work/application-outside.yml"
# 设置端口号
PORT=8082
# 获取当前文件夹下的所有文件
files=$(ls $directory)
str1=0.0.0
execute_file=null
for sfile in ${files}
do 
    file=${sfile}
	# 判断当前文件的后缀名是否为jar
	if [ "${file##*.}"x = "jar"x ] ; then
	    # 第一种方式
	    # 根据带有横线的规则进行切割得到版本号0.0.1  0.0.2再进行比较大小
		# 去除文件后缀名
		#file_name=${file%.*}
		# 从左边开始删除最后（最右边）一个 - 号及左边的所有字符
		#str2=${file_name##*-}
		# 第二种方式
		# 也可以直接使用文件的全名称进行比较大小，但文件名格式必须一致
		# 如：test-0.0.1.jar  test-0.0.2.jar
		# 全名称是根据字符串来进行比较，如果出现不一致的文件名会出现错误的比较 testapp0.0.1.jar  test0.0.2.jar
	    # 最终通过比较后启动文件为 testapp0.0.1.jar 显而易见这样的结果不是我们想要的
		str2=$file
		# 循环比较上一个文件与当前文件的版本大小
		if [ $(echo $str1 $str2 | awk '$1>$2 {print 1} $1==$2 {print 0} $1<$2 {print 2}') -eq 1 ] ;
		then
			echo "max version: ${str1}"
		else
			str1=$str2
			execute_file=$file
		fi
	fi
done
# 判断最新版本是否在运行
pid=`ps -ef|grep $execute_file|grep -v grep|awk '{print $2}' `
# 如果不存在则启动 
if [ -z "${pid}" ]; then 
	# $OUTSIDE_PROFILE 指定外部配置文件启动，按天打印日志到指定log文件夹下
	#nohup java $JVM -jar $execute_file $OUTSIDE_PROFILE >> ./log/nohup`date +%Y-%m-%d`.out 2>&1 &
	nohup java $JVM -jar $execute_file --server.port=$PORT > log.log 2>&1 & 
	echo "${execute_file} is running. Pid is ${pid}" 
else 
	echo "${execute_file} is running..."
fi