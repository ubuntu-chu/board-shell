#!/bin/sh
#
# 板载private脚本   用于执行一些板载私有的一些功能 
# 
#

. /etc/board/bootenv-utility.sh


if [ "$1" = "start" ]; then
	key_list="board_addr ipaddr"

	echo "Starting special private..."

	#处理uboot环境变量  更改uboot环境变量中的ipaddr   board_addr	
	for key in $key_list
	do
		#新值一定要存在！
		proc_line_return ${key} ${BOARD_INFO_FILE}
		if [ $? -eq 0 ]; then
			new_value=$PROC_LINE_VALUE
		else
			echo "$key do not exist in ${BOARD_INFO_FILE}! skip it!"
			continue
		fi

		ubootenv_modify $key $new_value
		if [ $? -ne 0 ];then
			echo "uboot env set error! please check what happened!"
			exit 1
		fi
	done
fi


exit 0

