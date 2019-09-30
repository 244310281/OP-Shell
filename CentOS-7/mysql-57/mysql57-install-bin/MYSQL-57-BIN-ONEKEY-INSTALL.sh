#!/bin/bash

#############################################################################################
# 脚本信息
#############################################################################################
# 作者：Dylan <1214966109@qq.com>   
# 用途：一键安装配置 MySQL 5.7 / 初始化 / 调优
# 系统：CentOS 7.x
# 时间：2019-09-28 17:24
#############################################################################################

#############################################################################################
# 脚本规范说明
#############################################################################################   
# 1. 安装包名称，版本都会以单独的变量单独定义组合，且抽离在脚本最前面便于维护
# 2. 变量 / 函数名称 / 数组都将使用全大写加下划线的形式，如：PLG_MYSQL_ECHO
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
# 1. 本脚本负责 MySQL 5.7 二进制一键安装 / 初始化 / 配置调优
# 2. MySQL 默认所以目录均在 /data 目录下，可根据自己需求修改
# 4. 目录解析（默认）：
#     /data/services/nginx：默认安装目录
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
PATH_MYSQL_BASE_INSTALL="${PATH_BASE}/services/mysql"
PATH_MYSQL_DATA="${PATH_BASE}/data/mysql"
PATH_MYSQL_LOG="${PATH_BASE}/logs/mysql"
PATH_MYSQL_BACKUP="${PATH_BASE}/backup/mysql"

# 安装包 / 模板路径
PATH_PWD=$(/usr/bin/pwd)
PATH_PKG="${PATH_PWD}/packages"
PATH_INIT_CONFIG="${PATH_PWD}/conf"
PATH_INIT_CONFIG_SYSTEM="${PATH_PWD}/../../common/conf/system"

# 进程用户
MYSQL_PROCESS_USER='mysql'

# 服务端口
MYSQL_PORT='3306'

# 数据库 ID
MYSQL_SERVER_ID='100'

# 分配内存，一般为服务器内存 80%
MYSQL_MEMORY='2G'

# 初始密码
MYSQL_INIT_PASSWORD='123456'

# 安装包下载地址
PKG_DOWNLOAD_URL='下载地址：https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.25-linux-glibc2.12-x86_64.tar.gz'

# 主程序解压包名称
PKG_MYSQL_NAME='mysql-5.7.25-linux-glibc2.12-x86_64'

# 安装包最终名称：tar.gz
PKG_MYSQL=${PKG_MYSQL_NAME}.tar.gz

# tar.gz 包组
ARR_PKG_TAR=(
${PKG_MYSQL}
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
# 安装检测函数
#############################################################################################
function FUNC_INSTALL_CHECK() {
  # 检查安装路径是否已被使用
  if [[ -d ${PATH_MYSQL_BASE_INSTALL} ]];then
    cd ${PATH_MYSQL_BASE_INSTALL}
    if [[ $(ls -l | wc -l) -gt 1 ]];then
      FUNC_ECHO_RED "安装路径 [${PATH_MYSQL_BASE_INSTALL}] 下已存在未知文件，请确认无用后删掉再次执行安装!"
      exit 1005
    fi
  fi
}

#############################################################################################
# 安装包检测函数
#############################################################################################
function FUNC_PACKAGE_CHECK() {
  # 检测安装包
  if [[ ! -f ${PATH_PKG}/${PKG_MYSQL} ]];then
    FUNC_ECHO_RED "缺失安装包：${PKG_MYSQL}，请上传到：${PATH_PKG}"
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
  FUNC_ECHO_GREEN "MySQL 安装完成，安装信息如下: "
  FUNC_ECHO_GREEN ${LINE}
  FUNC_ECHO_GREEN "安装路径: ${PATH_MYSQL_BASE_INSTALL}"
  FUNC_ECHO_GREEN "日志路径: ${PATH_MYSQL_LOG}"
  FUNC_ECHO_GREEN "备份路径: ${PATH_MYSQL_BACKUP}"
  FUNC_ECHO_GREEN "配置文件: /etc/my.cnf"
  FUNC_ECHO_GREEN "服务端口: ${MYSQL_PORT}"
  FUNC_ECHO_GREEN "初始密码: ${MYSQL_INIT_PASSWORD}"
  FUNC_ECHO_GREEN "启动命令: systemctl start mysqld"
  FUNC_ECHO_GREEN "安装用时：${TIME_USE} 秒"
  FUNC_ECHO_GREEN ${LINE}
}

#############################################################################################
# 系统调优函数
#############################################################################################
function FUNC_SYSTEM_TUNING() {
  # 打开文件数
  if [[ -f ${PATH_INIT_CONFIG_SYSTEM}/limits.conf ]];then
    mv /etc/security/limits.conf /etc/security/limits.conf-$(/usr/bin/date +%F)
    cp ${PATH_INIT_CONFIG_SYSTEM}/limits.conf /etc/security/
  fi

  # 内核调优
  if [[ -f ${PATH_INIT_CONFIG_SYSTEM}/sysctl.conf ]];then
    mv /etc/sysctl.conf /etc/sysctl.conf-$(/usr/bin/date +%F)
    cp ${PATH_INIT_CONFIG_SYSTEM}/sysctl.conf /etc/
  fi

  # SWAP 优化
  echo 0 >/proc/sys/vm/swappiness
  echo 'vm.swappiness = 0' >>/etc/sysctl.conf

  # 输出
  FUNC_ECHO_SUCCESS '系统调优参数：'
  /usr/sbin/sysctl -p
}

#############################################################################################
# 编译安装函数
#############################################################################################
function FUNC_INSTALL_MYSQL() {
  # 创建相关用户
  useradd -s /sbin/nologin ${MYSQL_PROCESS_USER}

  # 创建相关目录
  mkdir -p ${PATH_BASE}/services
  mkdir -p ${PATH_MYSQL_DATA}
  mkdir -p ${PATH_MYSQL_BACKUP}
  mkdir -p ${PATH_MYSQL_LOG}/{bin-log,error-log,relay-log,slow-log}

  # 修改目录权限
  chown -R ${MYSQL_PROCESS_USER}.${MYSQL_PROCESS_USER} ${PATH_MYSQL_DATA}
  chown -R ${MYSQL_PROCESS_USER}.${MYSQL_PROCESS_USER} ${PATH_MYSQL_LOG}

  cd ${PATH_PKG}

  # 解压 tar.gz
  for PKG in ${ARR_PKG_TAR[*]};do
    tar -zxf ${PKG}
    if [[ $? -ne 0 ]];then
      FUNC_ECHO_ERROR "${PKG} 解压失败，请检查该包是否存在问题！"
      exit 1008
    fi
  done

  # 移动包
  mv ${PKG_MYSQL_NAME} ${PATH_MYSQL_BASE_INSTALL}

  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR 'MySQL 解压包移动位置失败！'
    exit 1010
  fi

  # 添加环境变量
  echo "export PATH=\$PATH:${PATH_BASE}/services/mysql/bin" >> /etc/profile
  source /etc/profile
  mysql -V
}

#############################################################################################
# 初始化配置函数
#############################################################################################
function FUNC_INIT_MYSQL() {
  # 拷贝主配置文件
  mv /etc/my.cnf /etc/my.cnf-$(/usr/bin/date +%F)
  cp ${PATH_INIT_CONFIG}/my.cnf /etc/

  # 修改配置
  sed -i "s#MYSQL_PORT#${MYSQL_PORT}#g" /etc/my.cnf
  sed -i "s#MYSQL_SERVER_ID#${MYSQL_SERVER_ID}#g" /etc/my.cnf
  sed -i "s#MYSQL_PATH#${PATH_BASE}#g" /etc/my.cnf
  sed -i "s#MYSQL_MEMORY#${MYSQL_MEMORY}#g" /etc/my.cnf

  # 初始化数据库
  ${PATH_MYSQL_BASE_INSTALL}/bin/mysqld --initialize-insecure --user=${MYSQL_PROCESS_USER} --datadir=${PATH_MYSQL_DATA} --basedir=${PATH_MYSQL_BASE_INSTALL}
  
  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR 'MySQL 数据初始化失败！'
    exit 1011
  fi

  # 添加启动文件
echo "[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=${MYSQL_PROCESS_USER}
Group=${MYSQL_PROCESS_USER}
ExecStart=${PATH_MYSQL_BASE_INSTALL}/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE=5000" > /etc/systemd/system/mysqld.service

  # 启动 MySQL
  systemctl start mysqld
  sleep 5

  # 查看端口
  VAR_PORT_STATUS=$(netstat -tlunp | grep ${MYSQL_PORT} | wc -l)
  
  if [[ ${VAR_PORT_STATUS} -ne 1 ]];then
    FUNC_ECHO_ERROR 'MySQL 数据启动失败，请手动启动测试！'
    exit 1012
  fi

  # 初始化用户
  mysql -P ${MYSQL_PORT} -e "alter user root@'localhost' identified by ${MYSQL_INIT_PASSWORD};"

  if [[ $? -ne 0 ]];then
    FUNC_ECHO_ERROR 'MySQL 用户初始失败，请手动初始化！'
    exit 1013
  fi
}

#############################################################################################
# 安装程序开始
#############################################################################################
# 系统检查
FUNC_SYSTEM_CHECK
# 用户检查
FUNC_USER_CHECK
# 安装检测
FUNC_INSTALL_CHECK
# 安装包检测
FUNC_PACKAGE_CHECK
# 打印系统信息
FUNC_PRINT_SYSTEM_INFO

read -p "是否继续安装（默认 y） [y/n]: " VAR_CHOICE
case ${VAR_CHOICE} in
  [yY][eE][sS]|[yY])
    # 系统调优
    FUNC_SYSTEM_TUNING
    sleep 2
    # 编译安装
    FUNC_INSTALL_NGINX
    sleep 2
    # 安装
    FUNC_INSTALL_MYSQL
    sleep 2
    # 初始化
    FUNC_INIT_MYSQL
    sleep 2
    # 输出安装信息
    FUNC_INSTALL_INFO
  ;;
  [nN][oO]|[nN])
      FUNC_ECHO_YELLOW "安装即将终止..."
      exit
  ;;
  *)
    # 系统调优
    FUNC_SYSTEM_TUNING
    sleep 2
    # 编译安装
    FUNC_INSTALL_NGINX
    sleep 2
    # 安装
    FUNC_INSTALL_MYSQL
    sleep 2
    # 初始化
    FUNC_INIT_MYSQL
    # 输出安装信息
    FUNC_INSTALL_INFO
esac
