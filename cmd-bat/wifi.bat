@echo off
choice /C 123 /M "设置wifi请输入1,开启wifi请输入2,关闭wifi请输入3"
if errorlevel 3 goto off
if errorlevel 2 goto on
if errorlevel 1 goto install
:install
netsh wlan set hostednetwork mode=allow
netsh wlan set hostednetwork ssid=smart-campus key=88888888
netsh wlan start hostednetwork
goto end
:on
netsh wlan start hostednetwork
goto end
:off
netsh wlan stop hostednetwork
goto end
:end
echo.&pause
