#!/bin/bash

etc_board_rcs_file=/etc/board/rcS
if [ ! -e $etc_board_rcs_file ]; then
	echo "$etc_board_rcs_file do not exist!"
	exit 1
fi
. $etc_board_rcs_file

#站型定义
station_array=("center_station" "relay_station" "solid_station")

skip_key="skip"
#数组索引
array_index=0
param_station="--station"
param_debug="--debug"
param_help="--help"
param_current="--current"
cur_station=

help()
{
	echo "Usage            : $0 [$param_help|$param_station|$param_debug|$param_current]"
	echo "Param $param_help: show help"
	echo "Param $param_station: set station, valid station list:${station_array[*]}"
	echo "Param $param_current: show current station"
	echo "Param $param_debug: enable debug"
	exit 0
}

section_get()
{
	#去除=号左右的空格
	awk '/^'${1}'=\{/,/^\}/ {print $0 >> "'"${3}"'"}' "${2}"
}

show_current()
{
	
	exit 0
}

if [ -z $SHELL_TEMP_SYS_FILE ]; then
	SHELL_TEMP_SYS_FILE=/var/run/sys-temporary-file
fi
if [ -z $BOARD_INFO_FILE ]; then
	BOARD_INFO_FILE=/var/run/boardinfo
fi

echo -n "" > $SHELL_TEMP_SYS_FILE
#获取当前系统配置
section_get $SYS_CONFIG_KEY $BOARD_INFO_FILE $SHELL_TEMP_SYS_FILE
proc_line_return $STATION_KEY $SHELL_TEMP_SYS_FILE
if [ $? -eq 0 ]; then
	cur_station=$PROC_LINE_VALUE
else
	echo "cur station do not exist! please check what happened!(maybe rootfs version is old, please update rootfs first!)"
	exit 1
fi

#解析所有参数
while [ $# -gt 0  ]; 
do    
	case "$1" in
		$param_debug)
			# 是 "-d" 或 "--debug" 参数?
			DEBUG=1
			;;
		$param_current)
			show_current
			;;
		$param_help)
			help
			;;
		$param_station)
			assigned_station="$2"
			shift
			;;
		*)
			echo "$1 : invalid param! please check!"
			exit 2
			;;
	esac
	# 检查剩余的参数.
	shift       
done

echo "----------------current station----------------"
echo "station=$cur_station"

if [ -z $assigned_station ]; then

	echo "----------------change station----------------"
	while true
	do
		select var in "$skip_key" ${station_array[*]}; do
			break
		done

		if [ ! -z $var ]; then
			if [ $skip_key = $var ]; then
				new_station=$cur_station
			else
				new_station=$var
			fi
			break;
		else
			echo "input invalid! please input again!"
			continue
		fi
	done
else 
	#检查设置的baord_name是否正确
	arrayindex_get station_array "$assigned_station"
	if [ $? -ne 0 ]; then
		echo "station invalid! valid station:${station_array[*]}"
		exit 1
	fi
	new_station=$assigned_station
fi

if [ $new_station = $cur_station ]; then
	board_name_changed=0
else
	board_name_changed=1
fi

echo "-----------------new station------------------"

echo "station=$new_station"

sed -i "/^"${SYS_CONFIG_KEY}"={/,/^\}/ s/.*"${STATION_KEY}".*/    "${STATION_KEY}"="${new_station}"/g" $BOARD_INFO_SRC_FILE

echo "execute </etc/board/cpu-identify.sh start> to update boardinfo file"
/etc/board/cpu-identify.sh start > /dev/null

