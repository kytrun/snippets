:: 岚路迢迢 - by ChatGPT
:: 这个脚本用于从指定目录的所有子目录中随机打开一个 Markdown 文件。用户可以通过输入序号进入相应的子目录，然后脚本会在该目录中随机打开一个 Markdown 文件。
:: 每次脚本执行时，它会从根目录开始，并打印当前目录的所有子目录列表。然后，它要求用户输入一个序号以选择相应的子目录。
:: 如果不存在与输入序号对应的子目录，则脚本会输出“没有该序号对应的目录”的消息，并返回到目录列表。
:: 如果选择的目录中没有任何 .md 文件，则脚本会输出相应消息，返回到目录列表。
:: 如果选择的目录中存在 .md 文件，则脚本会在该目录中随机打开一个 Markdown 文件。
:: 用户可以输入“exit”退出脚本。

@echo off
setlocal enabledelayedexpansion

:LOOP
set rootDir=D:\收藏夹\obsidian notes

cd /d %rootDir%
echo 当前目录的子目录如下：
set count=0
for /d %%a in (*) do (
    set /a count+=1
    echo !count!. %%a
)

set /p choiceNum=请输入序号进入相应目录（输入exit退出脚本）：

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

echo 没有该序号对应的目录
pause
goto :LOOP

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
