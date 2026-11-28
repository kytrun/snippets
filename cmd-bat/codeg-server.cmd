@echo off
ping 127.0.0.1 -n 6 >nul
powershell -WindowStyle Hidden -Command "Start-Process 'codeg-server' -WindowStyle Hidden"
exit