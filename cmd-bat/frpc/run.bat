@echo off

if "%1"=="h" goto begin
start mshta vbscript:createobject("wscript.shell").run("""%~nx0"" h",0)(window.close)&&exit
:begin

taskkill /im frpc.exe /f 1>nul 2>nul

frpc.exe -c frpc.ini

