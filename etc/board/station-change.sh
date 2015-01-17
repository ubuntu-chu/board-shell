#!/bin/bash

#此文件暂时不再使用

exit 0

#包含partion_utility.sh的主要目的是更新恢复模式文件系统
partion_utility_file=/usr/sbin/partion_utility.sh
partion_utility_file_exsit=0
if [ -e $partion_utility_file ]; then
	. $partion_utility_file
	partion_utility_file_exsit=1
fi

etc_board_rcs_file=/etc/board/rcS
if [ ! -e $etc_board_rcs_file ]; then
	echo "$etc_board_rcs_file do not exist!"
	exit 1
fi
. $etc_board_rcs_file

[ -z $CAR_CENTRAL_STATION ] && CAR_CENTRAL_STATION="car_central_station"
[ -z $RELAY_STATION ] && RELAY_STATION="relay_station"
[ -z $METROCELL ] && METROCELL="metrocell"

#站型定义
station_array=($CAR_CENTRAL_STATION $RELAY_STATION $METROCELL)

skip_key="skip"
#数组索引
array_index=0
param_station="--station"
param_debug="--debug"
param_help="--help"
param_current="--current"
param_current_simple="--current_simple"
param_info="--info"
param_info_simple="--info_simple"
param_boardinfo_sync_dis="--boardinfo_sync_dis"
param_recovery_rootfs_sync="--recovery_rootfs_sync"
cur_station=
recovery_rootfs_sync=0
boardinfo_sync_dis=0
now_path=`pwd`

help()
{
	echo "Usage            : $0 [$param_help|$param_station|$param_debug|$param_current|$param_info|$param_recovery_rootfs_sync|$param_boardinfo_sync_dis]"
	echo "Param $param_help: show help"
	echo "Param $param_station: set station, valid station list:${station_array[*]}"
	echo "Param $param_current: show current station"
	echo "Param $param_info: show all stations"
	echo "Param $param_debug: enable debug"
	echo "Param $param_boardinfo_sync_dis: disable sync boardinfo"
	echo "Param $param_recovery_rootfs_sync: sync recovery rootfs"
	exit 0
}

show_current()
{
	echo "----------------current station----------------"
	echo "station=$cur_station"
}

show_info()
{
	echo "----------------all invalid stations----------------"
	echo "stations=${station_array[*]}"
	exit 0
}

arrayindex_get()
{
	array_index=0
	eval array_size=\${#${1}[*]}
	debug echo  "array_size=$array_size"
	while :;
	do
		eval "array_index_value=\${$1[${array_index}]}"
		debug echo "$1[$array_index]=$array_index_value"
		if [ ${array_index_value} = "$2" ]; then
			break
		fi
		array_index=$(($array_index+1))
		if [ $array_index -ge ${array_size} ]; then
			debug echo "$2 can not be found in array:$1"
			return 1
		fi
	done
	debug echo "array_index=$array_index"

	return 0
}

if [ -z $SHELL_TEMP_SYS_FILE ]; then
	SHELL_TEMP_SYS_FILE=/var/run/sys-temporary-file
fi
if [ -z $BOARD_INFO_FILE ]; then
	BOARD_INFO_FILE=/var/run/boardinfo
fi

echo -n "" > $SHELL_TEMP_SYS_FILE
#获取当前系统配置
section_content_get $SYS_CONFIG_KEY $BOARD_INFO_SRC_FILE $SHELL_TEMP_SYS_FILE
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
			exit 0
			;;
		$param_current_simple)
			echo "$cur_station"
			exit 0
			;;
		$param_help)
			help
			;;
		$param_info)
			show_info
			;;
		$param_info_simple)
			echo "${station_array[*]}"
			exit 0
			;;
		$param_station)
			assigned_station="$2"
			shift
			;;
		$param_recovery_rootfs_sync)
			recovery_rootfs_sync=1
			;;
		$param_boardinfo_sync_dis)
			boardinfo_sync_dis=1
			;;
		*)
			echo "$1 : invalid param! please check!"
			exit 2
			;;
	esac
	# 检查剩余的参数.
	shift       
done

show_current

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

rcs_board_file="rcS.board"
cd $BOARD_ENTRY_SHELL_PATH
#更改$BOARD_ENTRY_SHELL_PATH下的相关链接文件  
for file in "boardinfo.define" "rcS.define" "$rcs_board_file";
do
	ln -sf $new_station/$file $file
done

if [ ! $new_station = $cur_station ]; then
	#sed -i "/^"${SYS_CONFIG_KEY}"={/,/^\}/ s/.*"${STATION_KEY}".*/    "${STATION_KEY}"="${new_station}"/g" $BOARD_INFO_SRC_FILE

	#更改/opt/itl/sbin下连接文件
	#先判断rcS.board是否为链接文件
#	cd /opt/itl/sbin
#	if [ -L $rcs_board_file ]; then
#		ln -sf $new_station/$rcs_board_file $rcs_board_file
#	fi
	cd $now_path

	if [ $boardinfo_sync_dis -eq 0 ]; then
		echo "execute <$BOARD_ENTRY_SHELL_PATH/cpu-identify.sh start> to update boardinfo file"
		$BOARD_ENTRY_SHELL_PATH/cpu-identify.sh start > /dev/null
	fi

	if [ $recovery_rootfs_sync -eq 1 ]; then
		if [ $partion_utility_file_exsit -eq 1 ]; then
			if [ -z $RECOVER_ROOTFS_PARTION_NAME ]; then
				FLASH_RECOVER_ROOTFS_PARTION_NAME="rootfs-recover" 
			else
				FLASH_RECOVER_ROOTFS_PARTION_NAME=$RECOVER_ROOTFS_PARTION_NAME
			fi

			#拷贝boardinfo.define文件
			boardinfo_define_copy  $FLASH_RECOVER_ROOTFS_PARTION_NAME
		fi
	fi
else
	echo "cur_station = new_station, so do not need to update boardinfo file"
fi

exit 0

