@echo off
setlocal EnableDelayedExpansion
rem 设置输出的文字颜色
color 3
rem 设置标题
title Fuck Java
rem 通过执行vbs命令申请管理员权限（如果无法运行，请删除这段代码，然后右键[以管理员身份运行]）
PUSHD %~DP0 & cd /d "%~dp0"
%1 %2
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :runas","","runas",1)(window.close)&goto :eof
:runas
color 2
rem kill java 进程
taskkill /f /t /IM Java.exe
pause