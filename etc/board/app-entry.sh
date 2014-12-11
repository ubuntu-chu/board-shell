#!/bin/sh
#
# 目的：当系统挂载恢复所用根文件系统时  不自动启动应用程序 
#

. /etc/board/rcS

if [ "$1" = "start" ]; then

	proc_cmdline_value $RECOVERY_KEY 
	if [ $? -eq 0 ]; then
		value=$PROC_LINE_VALUE
		#恢复根文件系统挂载时  不自动启动应用程序
		if [ $value -eq 1 ]; then
			debug echo "do not auto start app in recoveryfs"
			exit 0
		fi
	fi
fi

debug echo $@
${APP_ENTRY_SHELL_PATH}/${APP_ENTRY_SHELL} $@


