:: 将本地 minio 地址、账号信息添加到 mc 的配置文件中，见 "C:\Users\用户名\mc\config.json"
.\mc.exe config host add local http://localhost:9000 %MINIO_ROOT_USER% %MINIO_ROOT_PASSWORD%

:: 创建一个存储桶，如果存在则跳过
.\mc.exe mb --ignore-existing local/local-store

:: 设置可公开匿名下载
.\mc.exe anonymous set download local/local-store