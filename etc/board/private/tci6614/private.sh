#!/bin/bash
#
# 板载private脚本   用于执行一些板载私有的一些功能 
# 
#
. /etc/board/rcS

auto_change_board_name()
{
	cpu_id_file=/proc/itl/cpu_id
	board_name_file=/proc/itl/board_name

	if [ ! -r $cpu_id_file -o ! -r $board_name_file ]; then
		echo "cpu id file or board name file do not exist or can not read! please check what happened!"
		return 1
	fi
	cpu_id=`cat $cpu_id_file`
	board_name=`cat $board_name_file`
	case "$cpu_id" in
		"0")
			expect_board_name="itl-bbu"
			;;

		"3")
			expect_board_name="itl-mesh"
			;;

		*)
			echo "invalid cpu id"
			exit 1
			;;
	esac

	if [ ! $board_name = $expect_board_name ]; then
		/etc/board/boarddefine-change.sh --board_name $expect_board_name
	fi
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
			auto_change_board_name
			;;

		"$RELAY_STATION")
			auto_change_board_name
			;;

		"$METROCELL")
			auto_change_board_name
			;;

		*)
			echo "invalid station[$station]"
			;;
	esac
fi


exit 0

