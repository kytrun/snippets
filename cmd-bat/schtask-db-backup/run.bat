echo off

REM *******��ʼִ�ж�ʱ���񴴽�******

REM -------�������ݿⱸ���ļ���-------
mkdir D:\db-backup
mkdir D:\db-backup-latest

REM ������ʱ����ÿ��1:00 ���е�ǰĿ¼�µ� db_backup.bat (https://docs.microsoft.com/zh-cn/windows-server/administration/windows-commands/schtasks-create)
schtasks /create /tn ���ݿⶨʱ���� /tr "%~dp0db-backup.bat" /sc daily /st 01:00

REM *******����ִ�ж�ʱ���񴴽�******

echo on

pause