#!/bin/bash

#############################################################################################
# 脚本信息
#############################################################################################
# 作者：Dylan <1214966109@qq.com>   
# 用途：一键 Nginx 编译安装 / 初始化 / 调优
# 系统：CentOS 7.x
# 时间：2019-07-27 14:45
#############################################################################################

#############################################################################################
# 脚本规范说明
#############################################################################################   
# 1. 安装包名称，版本都会以单独的变量单独定义组合，且抽离在脚本最前面便于维护
# 2. 变量 / 函数名称 / 数组都将使用全大写加下划线的形式，如：PLG_NGX_ECHO
# 3. 各个分类都将以单独的名称开始
#     普通变量：VAR_XXX_XXX
#     包名变量：PKG_XXX
#     插件变量：PKG_PLG_XXX_XXX
#     依赖变量：PKG_DEP_XXX_XXX
#     解压变量：PKG_XXX_NAME
#     版本变量：VER_XXX
#     函数名称：FUNC_XXX_XXX
#     数组名称：ARR_XXX_XXX
#############################################################################################

#############################################################################################
# 脚本功能说明
#############################################################################################   
# 1. 本脚本负责 nginx 一键编译安装 / 内核调优 / 配置调优
# 2. nginx 默认所以目录均在 /data 目录下，可根据自己需求修改
# 3. 在 nginx 的 conf/templates 目录中提供了常用的大部分 nginx 配置示例可供参考
# 4. 目录解析（默认）：
#     /data/services/nginx：默认安装目录
#     /data/logs/nginx：默认日志路径
#     /data/backup/nginx：默认备份路径
#     /data/www/nginx：默认项目目录
#     /data/services/nginx/conf/users：默认用户认证文件目录
#     /data/services/nginx/conf/templates：默认配置示例目录
#     /data/services/nginx/conf/vhosts：默认虚拟主机目录
#     /data/services/nginx/conf/tcp：默认TCP代理配置目录
#     /data/services/nginx/conf/certs：默认 ssl 证书目录
#############################################################################################

#############################################################################################
# 导入系统变量
#############################################################################################
. /etc/init.d/functions
source /etc/profile

#############################################################################################
# 服务变量定义
#############################################################################################
# 线条
LINE='---------------------------------------------------------------------------------------'

# 基础路径 / 安装路径 / 配置路径 / 日志路径 / 项目路径 / 备份路径
PATH_BASE="/data"
PATH_NGX_BASE_INSTALL="${PATH_BASE}/services/nginx"
PATH_CONFIG="${PATH_NGX_BASE_INSTALL}/conf"
PATH_NGX_LOG="${PATH_BASE}/logs/nginx"
PATH_WEB="${PATH_BASE}/www/nginx"
PATH_BACKUP="${PATH_BASE}/backup/nginx"

# 安装包 / 模板路径
PATH_PWD=$(/usr/bin/pwd)
PATH_PKG="${PATH_PWD}/packages"
PATH_INIT_CONFIG="${PATH_PWD}/conf"
PATH_INIT_CONFIG_TEMPLATE="${PATH_INIT_CONFIG}/templates"
PATH_INIT_CONFIG_YUM="${PATH_INIT_CONFIG}/yum"
PATH_INIT_CONFIG_SYSTEM="${PATH_INIT_CONFIG}/system"

# 进程用户
USER_PROCESS='root'

# 安装包下载地址
PKG_DOWNLOAD_URL='源码包下载链接: https://pan.baidu.com/s/1IpRtZgYFb-Kf71ED3pBEwQ 提取码: 2k6t'

# 主程序解压包名称
PKG_NGX_NAME='nginx-1.16.0'

# 依赖库解压包名称
PKG_DEP_OPENSSL_NAME='openssl-1.1.1c'
PKG_DEP_PCRE_NAME='pcre-8.43'
PKG_DEP_ZLIB_NAME='zlib-1.2.11'

# 插件解压包名称
PKG_PLG_ECHO_NAME='echo-nginx-module-master'
PKG_PLG_CACHE_NAME='ngx_cache_purge-master'
PKG_PLG_UPLOAD_NAME='nginx-upload-module-master'
PKG_PLG_FAIR_NAME='nginx-upstream-fair-master'
PKG_PLG_FANCYINDEX_NAME='ngx-fancyindex-master'
PKG_PLG_PROXY_NAME='ngx_http_proxy_connect_module-master'
PKG_PLG_CODE_NAME='ngx_http_status_code_counter-master'

# 安装包最终名称：tar.gz
PKG_NGX=${PKG_NGX_NAME}.tar.gz
PKG_DEP_OPENSSL=${PKG_DEP_OPENSSL_NAME}.tar.gz
PKG_DEP_PCRE=${PKG_DEP_PCRE_NAME}.tar.gz
PKG_DEP_ZLIB=${PKG_DEP_ZLIB_NAME}.tar.gz

# 安装包最终名称：zip
PKG_PLG_ECHO=${PKG_PLG_ECHO_NAME}.zip
PKG_PLG_CACHE=${PKG_PLG_CACHE_NAME}.zip
PKG_PLG_UPLOAD=${PKG_PLG_UPLOAD_NAME}.zip
PKG_PLG_FAIR=${PKG_PLG_FAIR_NAME}.zip
PKG_PLG_FANCYINDEX=${PKG_PLG_FANCYINDEX_NAME}.zip
PKG_PLG_PROXY=${PKG_PLG_PROXY_NAME}.zip
PKG_PLG_CODE=${PKG_PLG_CODE_NAME}.zip

# 安装包数组
ARR_PKG=(
${PKG_NGX}
${PKG_DEP_OPENSSL}
${PKG_DEP_PCRE}
${PKG_DEP_ZLIB}
${PKG_PLG_ECHO}
${PKG_PLG_CACHE}
${PKG_PLG_UPLOAD}
${PKG_PLG_FAIR}
${PKG_PLG_FANCYINDEX}
${PKG_PLG_PROXY}
${PKG_PLG_CODE}
)

# tar.gz 包组
ARR_PKG_TAR=(
${PKG_NGX}
${PKG_DEP_OPENSSL}
${PKG_DEP_PCRE}
${PKG_DEP_ZLIB}
)

# zip 包组
ARR_PKG_ZIP=(
${PKG_PLG_ECHO}
${PKG_PLG_CACHE}
${PKG_PLG_UPLOAD}
${PKG_PLG_FAIR}
${PKG_PLG_FANCYINDEX}
${PKG_PLG_PROXY}
${PKG_PLG_CODE}
)

# 解压包数组
ARR_PKG_NAME=(
${PKG_NGX_NAME}
${PKG_DEP_OPENSSL_NAME}
${PKG_DEP_PCRE_NAME}
${PKG_DEP_ZLIB_NAME}
${PKG_PLG_ECHO_NAME}
${PKG_PLG_CACHE_NAME}
${PKG_PLG_UPLOAD_NAME}
${PKG_PLG_FAIR_NAME}
${PKG_PLG_FANCYINDEX_NAME}
${PKG_PLG_PROXY_NAME}
${PKG_PLG_CODE_NAME}
)

#############################################################################################
# 颜色输出函数
#############################################################################################
function FUNC_COLOR_TEXT() {
  echo -e " \e[0;$2m$1\e[0m"
}

function FUNC_ECHO_RED() {
  echo $(FUNC_COLOR_TEXT "$1" "31")
}

function FUNC_ECHO_GREEN() {
  echo $(FUNC_COLOR_TEXT "$1" "32")
}

function FUNC_ECHO_YELLOW() {
  echo $(FUNC_COLOR_TEXT "$1" "33")
}

function FUNC_ECHO_BLUE() {
  echo $(FUNC_COLOR_TEXT "$1" "34")
}

#############################################################################################
# 颜色通知输出函数
#############################################################################################
# 通知信息
function FUNC_ECHO_INFO() {
  echo $(FUNC_COLOR_TEXT "${LINE}" "33")
  echo $(FUNC_COLOR_TEXT "$1" "33")
  echo $(FUNC_COLOR_TEXT "${LINE}" "33")
}

# 完成信息
function FUNC_ECHO_SUCCESS() {
  echo $(FUNC_COLOR_TEXT "${LINE}" "32")
  echo $(FUNC_COLOR_TEXT "$1" "32")
  echo $(FUNC_COLOR_TEXT "${LINE}" "32")
}

# 错误信息
function FUNC_ECHO_ERROR() {
  echo $(FUNC_COLOR_TEXT "${LINE}" "31")
  echo $(FUNC_COLOR_TEXT "$1" "31")
  echo $(FUNC_COLOR_TEXT "${LINE}" "31")
}

#############################################################################################
# 系统版本检测函数
#############################################################################################
function FUNC_SYSTEM_CHECK() {
  VAR_SYSTEM_FLAG=$(/usr/bin/cat /etc/redhat-release | grep 'CentOS' | grep '7' | wc -l)
  if [[ ${VAR_SYSTEM_FLAG} -ne 1 ]];then
    FUNC_ECHO_ERROR '本脚本基于 [ CentOS 7 ] 编写，目前暂不支持其他版本系统！'
    exit 1001
  fi
}

#############################################################################################
# 用户检测函数
#############################################################################################
function FUNC_USER_CHECK() {
  VAR_USER=$(/usr/bin/whoami)
  if [[ ${VAR_USER} != 'root' ]];then
    FUNC_ECHO_ERROR '脚本目前只支持 [ root ] 用户执行，请先切换用户...'
    exit 1002
  fi
}

#############################################################################################
# 服务器联网函数
#############################################################################################
function FUNC_NETWORK_CHECK() {
  VAR_PING_NUM=$(/usr/bin/ping -c 3 www.baidu.com | grep 'icmp_seq' | wc -l)
  if [[ ${VAR_PING_NUM} -ne 0 ]];then
    FUNC_ECHO_ERROR '网络连接失败，请先配置好网络连接...'
    exit 1004
  fi
}

#############################################################################################
# 安装检测函数
#############################################################################################
function FUNC_INSTALL_CHECK() {
  # 检查安装路径是否已被使用
  if [[ -d ${PATH_NGX_BASE_INSTALL} ]];then
    cd ${PATH_NGX_BASE_INSTALL}
    if [[ $(ls -l | wc -l) -gt 1 ]];then
      FUNC_ECHO_RED "安装路径下已存在未知文件，请确认无用后删掉再次执行安装!"
      exit 1005
    fi
}

#############################################################################################
# 安装包检测函数
#############################################################################################
function FUNC_PACKAGE_CHECK() {
  # 不存在的数组
  ARR_NOT_EXIST_PKG=()
  
  # 检测安装包
  cd ${PATH_PKG}
  for PKG in ${ARR_PKG[*]};do
    if [[ -f ${PKG} ]];then
      ARR_NOT_EXIST_PKG[${#ARR_NOT_EXIST_PKG[@]}]=${PKG}
    fi
  done

  # 输出不存在安装包
  if [[ ${#ARR_NOT_EXIST_PKG[@]} -ne 0 ]];then
    FUNC_ECHO_ERROR '缺失安装包列表：' 
    for PKG in ${ARR_NOT_EXIST_PKG[*]};do
      FUNC_ECHO_RED "缺失安装包：${PKG}"
    done
    FUNC_ECHO_RED ${PKG_DOWNLOAD_URL}
    exit 1006
  fi
}

#############################################################################################
# 打印系统信息
#############################################################################################
function FUNC_PRINT_SYSTEM_INFO() {
  # 开始计时
  TIME_START=$(/usr/bin/date +%s)

  # 获取系统信息
  SYSTEM_DATE=$(/usr/bin/date)
  SYSTEM_VERSION=$(/usr/bin/cat /etc/redhat-release)
  SYSTEM_CPU=$(/usr/bin/cat /proc/cpuinfo | grep 'model name' | head -1 | awk -F: '{print $2}' | sed 's#^[ \t]*##g')
  SYSTEM_CPU_NUMS=$(/usr/bin/cat /proc/cpuinfo | grep 'model name' | wc -l)
  SYSTEM_KERNEL=$(/usr/bin/uname -a | awk '{print $3}')
  SYSTEM_IPADDR=$(/usr/sbin/ip addr | grep inet | grep -vE 'inet6|127.0.0.1' | awk '{print $2}')
    
  # 打印系统信息
  FUNC_ECHO_YELLOW ${LINE}
  echo "服务器的信息: ${SYSTEM_IPADDR}"
  FUNC_ECHO_YELLOW ${LINE}
  echo "操作系统版本: ${SYSTEM_VERSION}"
  echo "系统内核版本: ${SYSTEM_KERNEL}"
  echo "处理器的型号: ${SYSTEM_CPU}"
  echo "处理器的核数: ${SYSTEM_CPU_NUMS}"
  echo "系统当前时间: ${SYSTEM_DATE}"
  FUNC_ECHO_YELLOW ${LINE}
}

#############################################################################################
# 打印安装信息
#############################################################################################
function FUNC_INSTALL_INFO() {
  # 结束计时 / 计算耗时
  TIME_STOP=$(/usr/bin/date +%s)
  TIME_USE=$((${TIME_STOP} - ${TIME_START}))
    
  # 打印安装信息
  FUNC_ECHO_GREEN ${LINE}
  FUNC_ECHO_GREEN "Nginx 安装完成，但是未启动，安装信息如下: "
  FUNC_ECHO_GREEN ${LINE}
  FUNC_ECHO_GREEN "安装路径: ${PATH_NGX_BASE_INSTALL}"
  FUNC_ECHO_GREEN "日志路径: ${PATH_NGX_LOG}"
  FUNC_ECHO_GREEN "项目路径: ${PATH_WEB}"
  FUNC_ECHO_GREEN "备份路径: ${PATH_NGX_BACKUP}"
  FUNC_ECHO_GREEN "模板路径: ${PATH_CONFIG}/templates"
  FUNC_ECHO_GREEN "认证路径: ${PATH_CONFIG}/users"
  FUNC_ECHO_GREEN "证书路径: ${PATH_CONFIG}/certs"
  FUNC_ECHO_GREEN "主机路径: ${PATH_CONFIG}/vhosts"
  FUNC_ECHO_GREEN "TCP 代理: ${PATH_CONFIG}/tcp"
  FUNC_ECHO_GREEN "配置检查: ${PATH_NGX_BASE_INSTALL}/sbin/nginx -t"
  FUNC_ECHO_GREEN "启动命令: ${PATH_NGX_BASE_INSTALL}/sbin/nginx"
  FUNC_ECHO_GREEN "安装用时：${TIME_USE} 秒"
  FUNC_ECHO_GREEN ${LINE}
}

#############################################################################################
# 系统调优函数
#############################################################################################
function FUNC_SYSTEM_TUNING() {
  # 创建相关目录
  mkdir -p ${PATH_NGX_LOG}
  mkdir -p ${PATH_WEB}
  mkdir -p ${PATH_BACKUP}

  # 打开文件数
  if [[ -f ${PATH_INIT_CONFIG_SYSTEM}/limits.conf ]];then
    mv /etc/security/limits.conf ${PATH_BACKUP}
    cp ${PATH_INIT_CONFIG_SYSTEM}/limits.conf /etc/security/
  fi

  # 内核调优
  if [[ -f ${PATH_INIT_CONFIG_SYSTEM}/sysctl.conf ]];then
    mv /etc/sysctl.conf ${PATH_BACKUP}
    cp ${PATH_INIT_CONFIG_SYSTEM}/sysctl.conf /etc/
  fi

  # 输出
  FUNC_ECHO_SUCCESS '系统调优参数：'
  /usr/sbin/sysctl -p
}

#############################################################################################
# 依赖安装函数
#############################################################################################
function FUNC_YUM_DEPENDS() {
  # yum 配置
  if [[ -f ${PATH_INIT_CONFIG_YUM}/nginx-ali.repo ]];then
    cp ${PATH_INIT_CONFIG_YUM}/nginx-ali.repo /etc/yum.repos.d/
  fi

  if [[ -f ${PATH_INIT_CONFIG_YUM}/nginx-epel.repo ]];then
    cp ${PATH_INIT_CONFIG_YUM}/nginx-epel.repo /etc/yum.repos.d/
  fi

  # 基础依赖安装
  yum -y install patch gcc gcc-c++ automake autoconf libtool make glibc gd-devel pcre-devel libmcrypt-devel mhash-devel libxslt-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel libevent libevent-devel net-tools httpd-tools zip unzip
  
  # 输出
  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR 'YUM 安装依赖失败，检查 epel/ali 源配置是否成功！'
    exit 1007
  fi
}

#############################################################################################
# 编译安装函数
#############################################################################################
function FUNC_INSTALL_NGINX() {
  cd ${PATH_PKG}

  # 解压 tar.gz
  for PKG in ${ARR_PKG_TAR[*]};do
    tar -zxf ${PKG}
    if [[ $? -ne 0 ]];then
      FUNC_ECHO_ERROR '${PKG} 失败，请检查该源码包是否存在问题！'
      exit 1008
    fi
  done

  # 解压 zip
  for PKG in ${ARR_PKG_ZIP[*]};do
    unzip ${PKG}
    if [[ $? -ne 0 ]];then
      FUNC_ECHO_ERROR '${PKG} 失败，请检查该源码包是否存在问题！'
      exit 1009
    fi
  done

  # 隐藏 nginx 信息
  sed -i 's#"nginx/"#"WEB-SERVER/"#g' ${PKG_NGX_NAME}/src/core/nginx.h
  sed -i 's#"NGINX"#"WEB-SERVER"#g' ${PKG_NGX_NAME}/src/core/nginx.h
  sed -i 's#"Server: nginx"#"Server: WEB-SERVER"#g' ${PKG_NGX_NAME}/src/http/ngx_http_header_filter_module.c
  sed -i 's#"<hr><center>nginx</center>" CRLF##g' ${PKG_NGX_NAME}/src/http/ngx_http_special_response.c

  # 打补丁
  sed -i 's/default_port/no_port/g' ${PKG_PLG_FAIR_NAME}/ngx_http_upstream_fair_module.c
  cd ${PKG_NGX_NAME}
  patch -p1 < ${PATH_PKG}/${PKG_PLG_PROXY_NAME}/patch/proxy_connect_rewrite_101504.patch

  # 编译
  ./configure --prefix=${PATH_NGX_BASE_INSTALL} \
  --with-http_stub_status_module \
  --with-http_gzip_static_module \
  --with-http_secure_link_module \
  --with-http_flv_module \
  --with-http_ssl_module \
  --with-http_mp4_module \
  --with-stream \
  --with-http_realip_module \
  --with-http_v2_module \
  --with-http_sub_module \
  --with-http_image_filter_module \
  --with-pcre=../${PKG_DEP_PCRE_NAME} \
  --with-openssl=../${PKG_DEP_OPENSSL_NAME} \
  --with-zlib=../${PKG_DEP_ZLIB_NAME} \
  --add-module=../${PKG_PLG_UPLOAD_NAME} \
  --add-module=../${PKG_PLG_FAIR_NAME} \
  --add-module=../${PKG_PLG_CACHE_NAME} \
  --add-module=../${PKG_PLG_FANCYINDEX_NAME} \
  --add-module=../${PKG_PLG_ECHO_NAME} \
  --add-module=../${PKG_PLG_PROXY_NAME} \
  --add-module=../${PKG_PLG_CODE_NAME}

  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR '编译参数检查失败！'
    exit 1010
  fi

  make -j4 && make install
  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR '编译安装失败！'
    exit 1010
  fi
}

#############################################################################################
# 初始化配置函数
#############################################################################################
function FUNC_INIT_NGINX() {
  # 创建配置目录
  cd ${PATH_CONFIG} && mkdir -p {users,vhosts,certs,tcp,templates}
  
  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR '配置文件目录初始化失败，请检查！'
    exit 1010
  fi

  # 拷贝主配置文件
  mv ${PATH_CONFIG}/nginx.conf ${PATH_BACKUP}
  sed -i "s#/data/logs/nginx#${PATH_NGX_LOG}#g" ${PATH_CONFIG}/nginx.conf
  cp ${PATH_INIT_CONFIG_TEMPLATE}/nginx.conf ${PATH_CONFIG}

  # 配置 demo 文件
  mkdir ${PATH_WEB}/demo
  echo '<h1>Welcome to nginx!</h1>' > ${PATH_WEB}/demo/index.html
  sed -i "s#/data/www/nginx#${PATH_WEB}#g" ${PATH_CONFIG}/nginx.conf
  cp ${PATH_INIT_CONFIG_TEMPLATE}/demo.conf /${PATH_CONFIG}/vhost/

  # 添加其它配置模板
  cp ${PATH_INIT_CONFIG_TEMPLATE}/*.conf ${PATH_CONFIG}/templates/
}


#############################################################################################
# 安装程序开始
#############################################################################################
# 系统检查
FUNC_SYSTEM_CHECK
# 用户检查
FUNC_USER_CHECK
# 联网检测
FUNC_NETWORK_CHECK
# 安装检测
FUNC_INSTALL_CHECK
# 安装包检测
FUNC_PACKAGE_CHECK
# 打印系统信息
FUNC_INSTALL_INFO

read -p "是否继续安装（默认 y） [y/n]: " VAR_CHOICE
case ${VAR_CHOICE} in
  [yY][eE][sS]|[yY])
    # 系统调优
    FUNC_SYSTEM_TUNING
    # 依赖安装
    FUNC_YUM_DEPENDS
    # 编译安装
    FUNC_INSTALL_NGINX
    # 优化配置
    FUNC_INIT_NGINX
  ;;
  [nN][oO]|[nN])
      FUNC_ECHO_YELLOW "安装即将终止..."
      exit
  ;;
  *)
    # 系统调优
    FUNC_SYSTEM_TUNING
    # 依赖安装
    FUNC_YUM_DEPENDS
    # 编译安装
    FUNC_INSTALL_NGINX
    # 优化配置
    FUNC_INIT_NGINX
esac
