@echo off

setlocal enabledelayedexpansion
REM 端口号
set port=8774
for /f "delims= tokens=1" %%i in ('netstat -aon ^| findstr "0.0.0.0:%port%"') do (
set a=%%i
taskkill /f /pid "!a:~71,5!"
)
