@echo off
echo 警告：此操作将导入应用程序关联设置。
echo 请确保 "%~dp0AppAssociations.xml" 文件存在于脚本所在目录。
echo.
pause
echo.
echo 正在恢复默认应用程序关联...
REM 注意：原始命令中 /Image:C:\test\offline 参数适用于离线映像。
REM 对于当前运行的系统，通常不需要 /Image 参数，或者需要调整。
REM 以下命令假设您是要恢复到当前运行的系统。
REM 如果您确实要操作离线映像，请取消注释下一行并修改路径。
REM Dism /Image:C:\your_offline_image_mount_path /Import-DefaultAppAssociations:"%~dp0AppAssociations.xml"

REM 恢复到当前在线系统 (通常情况):
Dism /Online /Import-DefaultAppAssociations:"%~dp0AppAssociations.xml"

echo.
echo 恢复操作已尝试执行。
echo 如果遇到错误，请检查是否以管理员权限运行此脚本以及 "%~dp0AppAssociations.xml" 文件是否正确。
echo.
pause