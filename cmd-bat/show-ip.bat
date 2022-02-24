@echo off
SET IP=

REM 列出ipconfig /all命令中所有带有IPv4的行并输出到ipv4.txt文件中
ipconfig /all|FINDSTR "IPv4">ipv4.txt
SETLOCAL EnableDelayedExpansion
FOR /F "delims=" %%a IN (ipv4.txt) DO (
    REM 将每一行的值赋值给环境变量IP
    SET IP=%%a
    
    REM 将每一行第37至倒数第5个字符依次保存到ip.txt中。附带说明 >和>>区别在于>会覆盖文件，而>>会向文件末尾继续写入
    ECHO !IP:~37,-5!>>ip.txt
)
ENDLOCAL

REM 删除临时文件ipv4.txt
del ipv4.txt

REM 输出临时文件ip.txt的内容
type ip.txt

REM 删除临时文件ip.txt
del ip.txt

SET IP=
pause