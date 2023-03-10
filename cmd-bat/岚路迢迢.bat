@echo off
setlocal enabledelayedexpansion

set rootDir=D:\jianguoyun\webclip

cd /d %rootDir%
echo 当前目录的子目录如下：
set count=0
for /d %%a in (*) do (
    set /a count+=1
    echo !count!. %%a
)

set /p choiceNum=请输入序号进入相应目录：

set dirNum=0
for /d %%b in (*) do (
    set /a dirNum+=1
    if !dirNum! equ %choiceNum% (
        set choiceDir=%%b
        goto :startSearch
    )
)

echo 没有该序号对应的目录
pause
exit /b

:startSearch
echo 进入目录：%choiceDir%
cd /d "%rootDir%\%choiceDir%"

set /a fileCount=0
for /r %%c in (*.md) do (
    set /a fileCount+=1
    set "file[!fileCount!]=%%c"
)

if !fileCount! equ 0 (
    echo 该目录下没有任何 .md 文件
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
