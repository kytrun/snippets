echo off

REM *******开始执行定时任务创建******

REM -------创建数据库备份文件夹-------
mkdir D:\db-backup
mkdir D:\db-backup-latest

REM 创建定时任务：每天1:00 运行当前目录下的 db_backup.bat (https://docs.microsoft.com/zh-cn/windows-server/administration/windows-commands/schtasks-create)
schtasks /create /tn 数据库定时备份 /tr "%~dp0db-backup.bat" /sc daily /st 01:00

REM *******结束执行定时任务创建******

echo on

pause