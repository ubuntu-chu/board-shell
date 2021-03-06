#!/bin/sh
#

. /etc/board/rcS

#board entry shell
HOSTNAME_GENERATE_SHELL=hostname-generate.sh
INTERFACES_GENERATE_SHELL=interfaces-generate.sh
CPU_IDENTIFY_SHELL=cpu-identify.sh
PRIVATE_SHELL=private.sh

#customize services define
BOARD_SERVICES="mount-proc-sys udev depmod modules filesystems populate-volatile.sh debugfs.sh syslog $CPU_IDENTIFY_SHELL $HOSTNAME_GENERATE_SHELL hostname $INTERFACES_GENERATE_SHELL network inetd sshd $PRIVATE_SHELL $ETC_ENTRY_SHELL_VENDOR_PROC_SYS"
BOARD_SERVICES_R="$ETC_ENTRY_SHELL_VENDOR_PROC_SYS sshd inetd network syslog filesystems modules depmod  udev  mount-proc-sys"

#customize services
sed -i -e "s/^cfg_services=.*$/cfg_services=\"${BOARD_SERVICES}\"/" /etc/rc.d/rc.conf
sed -i -e "s/^cfg_services_r=.*$/cfg_services_r=\"${BOARD_SERVICES_R}\"/" /etc/rc.d/rc.conf

#create soft link in /etc/rc.d/init.d
ln -s -f ${BOARD_ENTRY_SHELL_PATH}/${ETC_APP_ENTRY_SHELL} ${ETC_APP_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS
ln -s -f ${BOARD_ENTRY_SHELL_PATH}/${HOSTNAME_GENERATE_SHELL} ${ETC_ENTRY_SHELL_PATH}/${HOSTNAME_GENERATE_SHELL}
ln -s -f ${BOARD_ENTRY_SHELL_PATH}/${INTERFACES_GENERATE_SHELL} ${ETC_ENTRY_SHELL_PATH}/${INTERFACES_GENERATE_SHELL}
ln -s -f ${BOARD_ENTRY_SHELL_PATH}/${CPU_IDENTIFY_SHELL} ${ETC_ENTRY_SHELL_PATH}/${CPU_IDENTIFY_SHELL}
ln -s -f ${BOARD_ENTRY_PRIVATE_SHELL_PATH}/${PRIVATE_SHELL} ${ETC_ENTRY_SHELL_PATH}/${PRIVATE_SHELL}


#创建软连接 -- boot环境变量配置文件
ln -s -f ${BOARD_ENTRY_PRIVATE_SHELL_PATH}/fw_env.config /etc/fw_env.config


