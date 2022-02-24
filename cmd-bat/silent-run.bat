@echo off
if "%1"=="h" goto begin
start mshta vbscript:createobject("wscript.shell").run("""%~nx0"" h",0)(window.close)&&exit
:begin
java -Xms32m -Xmx96m -Xss256k -Xmn8m -jar service-name-1.0.0.jar --spring.profiles.active=prod