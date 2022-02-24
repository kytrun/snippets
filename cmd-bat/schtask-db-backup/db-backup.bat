REM ******MySQL backup start********

@echo off

REM ----------Config start--------------

set mqsqldump="E:\mysql-8.0.18-winx64\bin\mysqldump"
set path="D:\db-backup"
set latest="D:\db-backup-latest"
set user="root"
set password="123"
set host="127.0.0.1"
set port="3306"
set database="db1 db2 db3"

REM ----------Config end---------------

REM 删除 30 天以前的文件
C:\Windows\System32\forfiles /p %path% /m backup_*.sql -d -30 /c "cmd /c del /f @path"

REM 时间格式设置，拼接到备份文件名后
set Ymd="%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%"


REM for 循环：将字符串分割成两一部分，一部分是第一个空格前的字串，另一部分是剩余的字串（tokens=1,*），
REM 第一部分保存在 a 变量中，第二部分保存在 b 变量中，这个 b 是自动的。

:DB_BACKUP
for /f "tokens=1,*" %%a in (%database%) do (
    %mqsqldump% --opt --single-transaction --user=%user% --password=%password% --host=%host% --protocol=tcp --port=%port% --default-character-set=utf8 --routines %%a > %path%\backup_%%a_%Ymd%.sql
    REM 复制到 latest 文件夹，用于增量同步
    copy %path%\backup_%%a_%Ymd%.sql %latest%\backup_%%a_latest.sql
    set database="%%b"
    goto DB_BACKUP
)
@echo on

REM ******MySQL backup end********