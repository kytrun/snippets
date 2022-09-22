# 腾讯云自动化助手命令
# 下载 jar 包并重启
cd /deploy/micro-cloud/micro-{{service-name}}/
# 重命名所有 jar 包为创建时间
for f in *.jar; do mv -n "$f" "$(date -r"$f" +"%Y%m%d_%H%M%S").jar"; done
# 下载新包
wget -O micro-{{service-name}}-{{version}}.jar "{{downlaod-url}}"
# 启动命令
setsid bash micro-{{service-name}}-prod.sh {{option}}