:: ����ű����ڴ�ָ��Ŀ¼��������Ŀ¼�������һ�� Markdown �ļ����û�����ͨ��������Ž�����Ӧ����Ŀ¼��Ȼ��ű����ڸ�Ŀ¼�������һ�� Markdown �ļ���
:: ÿ�νű�ִ��ʱ������Ӹ�Ŀ¼��ʼ������ӡ��ǰĿ¼��������Ŀ¼�б�Ȼ����Ҫ���û�����һ�������ѡ����Ӧ����Ŀ¼��
:: �����������������Ŷ�Ӧ����Ŀ¼����ű��������û�и���Ŷ�Ӧ��Ŀ¼������Ϣ�������ص�Ŀ¼�б�
:: ���ѡ���Ŀ¼��û���κ� .md �ļ�����ű��������Ӧ��Ϣ�����ص�Ŀ¼�б�
:: ���ѡ���Ŀ¼�д��� .md �ļ�����ű����ڸ�Ŀ¼�������һ�� Markdown �ļ���
:: �û��������롰exit���˳��ű���

@echo off
setlocal enabledelayedexpansion

:LOOP
set rootDir=D:\jianguoyun\webclip

cd /d %rootDir%
echo ��ǰĿ¼����Ŀ¼���£�
set count=0
for /d %%a in (*) do (
    set /a count+=1
    echo !count!. %%a
)

set /p choiceNum=��������Ž�����ӦĿ¼������exit�˳��ű�����

if /i "%choiceNum%"=="exit" (
    exit /b
)

set dirNum=0
for /d %%b in (*) do (
    set /a dirNum+=1
    if !dirNum! equ %choiceNum% (
        set choiceDir=%%b
        goto :startSearch
    )
)

echo û�и���Ŷ�Ӧ��Ŀ¼
pause
goto :LOOP

:startSearch
echo ����Ŀ¼��%choiceDir%
cd /d "%rootDir%\%choiceDir%"

set /a fileCount=0
for /r %%c in (*.md) do (
    set /a fileCount+=1
    set "file[!fileCount!]=%%c"
)

if !fileCount! equ 0 (
    echo ��Ŀ¼��û���κ� .md �ļ�
    pause
    goto :LOOP
)

set /a randNum=%random%!fileCount!
set /a index=0

for %%d in (%random%) do (
    set /a index=%%d%%fileCount
    if !index! equ 0 set /a index=1
)

start "" "!file[%index%]!"

goto :LOOP
