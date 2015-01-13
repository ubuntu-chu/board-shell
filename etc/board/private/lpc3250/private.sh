#!/bin/sh
#
# 板载private脚本   用于执行一些板载私有的一些功能 
# 
#

#里面间接source /etc/board/rcS
. /etc/board/private/bootenv-utility.sh

bootloader_params_modify()
{

	key_list="board_addr ipaddr"


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
}

if [ "$1" = "start" ]; then
	echo "Starting special private..."

	#获取站型信息
	if [ ! -z $SYS_STATION_FILE ]; then
		[ -r $SYS_STATION_FILE ] && station=`cat $SYS_STATION_FILE`
    fi
	[ -z $station ] && station=$CAR_CENTRAL_STATION

	echo "station=$station"

	case "$station" in
		"$CAR_CENTRAL_STATION")
			bootloader_params_modify
			;;

		"$RELAY_STATION")
			echo ""
			;;

		"$METROCELL")
			echo ""
			;;

		*)
			echo "invalid station[$station]"
			;;
	esac

fi

exit 0

