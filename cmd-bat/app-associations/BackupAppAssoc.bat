@echo off
echo 正在备份默认应用程序关联...
Dism /Online /Export-DefaultAppAssociations:"%~dp0AppAssociations.xml"
echo.
if exist "%~dp0AppAssociations.xml" (
    echo 备份成功！文件已保存到 "%~dp0AppAssociations.xml"
) else (
    echo 备份失败。请检查是否以管理员权限运行此脚本。
)
echo.
pause