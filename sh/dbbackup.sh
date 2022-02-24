#!/bin/bash

# MySQL 用户
user='root'
# MySQL 密码
userPWD='123'
# MySQL 端口
dbPort='3306'

# 需要定时备份的数据表列表
dbNames=(db1 db2 db3)

# 每次的备份数据以日期创建文件夹存放
DATE=`date -d "now" +%Y%m%d%H`
newdir=/data/dbbackup/${DATE}

# 创建新备份文件夹
mkdir ${newdir}
# 对备份数据库列表的所有数据库备份
for dbName in ${dbNames[*]}
do
  dumpFile=${dbName}-$DATE.sql.gz
  mysqldump --flush-logs --single-transaction -u${user} --port ${dbPort} -p${userPWD} ${dbName} | gzip > ${newdir}/${dumpFile}

  # 备份到腾讯云对象存储挂载目录
  cp /data/dbbackup/${DATE}/* /data/tencentcos/dbbackup/

done

# 删除过期备份数据（本地保留最近 30 天，对象存储保留最近 10 天）
find /data/dbbackup/ -mtime +30 -name "*" | xargs rm -rf
# 因为腾讯云挂载的目录的修改时间不自动更新，防止根目录被直接删除，故指定只删文件型的内容（linux 原生目录的会自动变化）
find /data/tencentcos/dbbackup/ -type f -mtime +10 -name "*" | xargs rm -rf