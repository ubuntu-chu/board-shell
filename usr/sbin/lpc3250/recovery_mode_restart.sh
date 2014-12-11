#!/bin/sh
#
# recovery_mode重启
# 
#

. /etc/board/private/bootenv-utility.sh

ubootenv_modify bootcmd "run recoverboot"
if [ $? -ne 0 ];then
	echo "uboot env set error! please check what happened!"
	exit 1
else
	echo "reboot to enter recovery mode"
	reboot
fi

exit 0

