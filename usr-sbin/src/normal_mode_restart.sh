#!/bin/sh
#
# recovery_mode重启
# 
#

. /etc/board/bootenv-utility.sh

ubootenv_modify bootcmd "auto_saveenv&&run normalboot"
if [ $? -ne 0 ];then
	exit 1
else
	echo "reboot to enter normal mode"
	reboot
fi

exit 0

