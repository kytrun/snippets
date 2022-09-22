# 腾讯云自动化助手命令
# 下载 jar 包并更新
cd /deploy/kiraku-cloud/kiraku-{{service-name}}/
# 重命名所有 jar 包为创建时间
# for f in *.jar; do mv -n "$f" "$(date -r"$f" +"%Y%m%d_%H%M%S").jar"; done
# 下载新包
wget -O kiraku-{{service-name}}-{{version}}.jar "{{downlaod-url}}"
# 启动命令
setsid bash kiraku-{{service-name}}-update.sh {{version}}