@echo off
setlocal enabledelayedexpansion

set rootDir=D:\jianguoyun\webclip

cd /d %rootDir%
echo ��ǰĿ¼����Ŀ¼���£�
set count=0
for /d %%a in (*) do (
    set /a count+=1
    echo !count!. %%a
)

set /p choiceNum=��������Ž�����ӦĿ¼��

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
exit /b

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
    exit /b
)

set /a randNum=%random%!fileCount!
set /a index=0

for %%d in (%random%) do (
    set /a index=%%d%%fileCount
    if !index! equ 0 set /a index=1
)

start "" "!file[%index%]!"

exit /b
