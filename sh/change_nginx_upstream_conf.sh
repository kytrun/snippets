#!/bin/bash
#####################################################
#    Name:           change_nginx_upstream_conf.sh
#    Version:        V1.0
#    Author:         运维菜鸟
#    Description:    更改nginx upstream配置文件    
#    Create Date:    2017-07-03
#    Email:            
#####################################################

#function name
function_name=$1
#pool name
pool_name=$2
#pool corresponding ip list
pool_ip_lists=$3
#pool corresponding tomcat port
pool_tomcat_port=$4
#upstream file location
ngx_upstream_file=$5


#检测pool在nginx upstream配置文件中是否存在
function check_pool_in_ngx_upstream() {
    grep -E "${pool_name}[^-]" ${ngx_upstream_file} >> /dev/null
    if [ $? -eq 0 ];then
        echo -e "\033[36m the ${pool_name} in ${ngx_upstream_file}. \033[0m"
    else
        echo -e "\033[31m the ${pool_name} not in ${ngx_upstream_file}. \033[0m"
        exit 1
    fi
}

#显示pool在nginx upstream配置文件中对应内容
function show_pool_in_ngx_upstream() {
    pool_name_first_line=`egrep -n "${pool_name}[^-]" ${ngx_upstream_file} | cut -d ":" -f1`
    line_list=`grep -n "^}" ${ngx_upstream_file} | cut -d ":" -f1`
    pool_name_end_line=${pool_name_first_line}
    for line in ${line_list[*]};do
        if [ $line -gt ${pool_name_first_line} ];then
            pool_name_end_line=${line}
            break;
        fi
    done
    sed -n "${pool_name_first_line},${pool_name_end_line}p" ${ngx_upstream_file}
}

#增加pool进nginx upstream配置文件
function add_pool_to_upstream() {
    #pool对应ip地址列表,多个ip以逗号改开
    pool_ip=`awk 'BEGIN{list="'${pool_ip_lists}'";split(list,ip_list,",");for(ip in ip_list){print ip_list[ip];}}'`
    for ip in ${pool_ip[*]};do
        echo "add ${pool_name} ${ip} in ${ngx_upstream_file}"
        sed -i '/upstream '${pool_name}'[^-]*{/a\\tserver '${ip}':'${pool_tomcat_port}';' ${ngx_upstream_file}
    done
    echo -e "\033[31m ====添加完成如下:==== \033[0m"
}

#在nginx upstream配置文件删除pool对应的ip地址
function delete_ip_from_upstream() {
    pool_name_first_line=`egrep -n "${pool_name}[^-]" ${ngx_upstream_file} | cut -d ":" -f1`
    line_list=`grep -n "^}" ${ngx_upstream_file} | cut -d ":" -f1`
    pool_name_end_line=${pool_name_first_line}
    for line in ${line_list[*]};do
        if [ $line -gt ${pool_name_first_line} ];then
            pool_name_end_line=${line}
            break;
        fi
    done
    #获取pool对应配置行数
    line_count=`sed -n "${pool_name_first_line},${pool_name_end_line}p" ${ngx_upstream_file} | wc -l`
    #如果某个pool的配置行数等于3,则不能进行删除操作
    if [ ${line_count} -eq 3 ];then
        echo -e "\033[31m this is lowest configure. \033[0m"
    fi
    #删除pool_ip_lists中包含的ip地址
    for ((i=${pool_name_first_line};i<=${pool_name_end_line};i++));do
        pool_ip=`awk 'BEGIN{list="'${pool_ip_lists}'";split(list,ip_list,",");for(ip in ip_list){print ip_list[ip];}}'`
        line_context=`sed -n ''${i}'p' ${ngx_upstream_file}`
        for ip in ${pool_ip[*]};do
            echo "this line ${line_context} has ${ip}" | egrep "${ip}:${pool_tomcat_port}"
            if [ $? -eq 0 ];then
                #将包含删除ip的行,替换为空行
                sed -i ''${i}'s/.*'${ip}':'${pool_tomcat_port}'.*//ig' ${ngx_upstream_file}
                #sed -i ''${i}'d' ${ngx_upstream_file}
                echo -e "\033[36m delete ${pool_name} from ${ngx_upstream_file} where ip = ${ip}. \033[0m"
            fi
        done
    done
    #删除文件中的空行
    sed -i '/^$/d' ${ngx_upstream_file}
    echo -e "\033[31m ====删除完成如下:==== \033[0m"
}


#调用方法
if [ $# -eq 5 ];then
    case $1 in
        add)
            check_pool_in_ngx_upstream;
            show_pool_in_ngx_upstream;
            add_pool_to_upstream;
            show_pool_in_ngx_upstream;
            ;;
        delete)
            check_pool_in_ngx_upstream;
            show_pool_in_ngx_upstream;
            delete_ip_from_upstream;
            show_pool_in_ngx_upstream;
            ;;
        *)
            $"Usage: {sh change_nginx_upstream_conf.sh add chat-frontier-web 10.10.13.194 8080 /etc/nginx/conf.d/upstream.conf|sh change_nginx_upstream_conf.sh add chat-frontier-web 10.10.13.194 8080 /etc/nginx/conf.d/upstream.conf}"
            exit 3
    esac
else
    echo "variables count not eq 5.please check the usage."
fi