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

REM ɾ�� 30 ����ǰ���ļ�
C:\Windows\System32\forfiles /p %path% /m backup_*.sql -d -30 /c "cmd /c del /f @path"

REM ʱ���ʽ���ã�ƴ�ӵ������ļ�����
set Ymd="%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%"


REM for ѭ�������ַ����ָ����һ���֣�һ�����ǵ�һ���ո�ǰ���ִ�����һ������ʣ����ִ���tokens=1,*����
REM ��һ���ֱ����� a �����У��ڶ����ֱ����� b �����У���� b ���Զ��ġ�

:DB_BACKUP
for /f "tokens=1,*" %%a in (%database%) do (
    %mqsqldump% --opt --single-transaction --user=%user% --password=%password% --host=%host% --protocol=tcp --port=%port% --default-character-set=utf8 --routines %%a > %path%\backup_%%a_%Ymd%.sql
    REM ���Ƶ� latest �ļ��У���������ͬ��
    copy %path%\backup_%%a_%Ymd%.sql %latest%\backup_%%a_latest.sql
    set database="%%b"
    goto DB_BACKUP
)
@echo on

REM ******MySQL backup end********