#!/bin/bash

. /etc/board/rcS

#支持的板型列表
board_name_1="rfu_rru"
board_name_2="cs_rfu_rru"
board_name_3="ss_rfu_rru"
board_name_4="ifu_ccu"
board_name_5="rs_ccu"

board_name_array=($board_name_1 $board_name_2 $board_name_3 $board_name_4 $board_name_5)
default_board_type=
default_hardware_list=()

new_board_name=
new_board_type=
new_hardware=
skip_key="skip"
manual_set=0
with_hardware=0

boarddefine_get()
{
	case $1 in
		$board_name_1 )
			default_board_type=1000
			default_hardware_list=(3)
			;;
		$board_name_2 )
			default_board_type=1100
			default_hardware_list=(1)
			;;
		$board_name_3 )
			default_board_type=1200
			default_hardware_list=(1)
			;;
		$board_name_4 )
			default_board_type=2000
			default_hardware_list=(1)
			;;
		$board_name_5 )
			default_board_type=2100
			default_hardware_list=(1)
			;;
		*)
			echo "invalid board name: $1"
			exit 1
			;;
	esac
}

help(){
	echo "Usage                 : $0 [board_name] [hardware]"
	echo "Param board_name      : ${board_name_array[*]}"
	echo "Param hardware        : "
	for name in ${board_name_array[*]};
	do
		boarddefine_get $name
		echo "                        $name - (${default_hardware_list[*]})"
	done
	exit 1

}

if [ $# -ge 1 ]; then

	if [ $1 = "help" ]; then
		help
	else
		echo "-------------manual change board define------------"
		manual_set=1
		new_board_name=$1
		var=$new_board_name
	fi
	if [ $# -eq 2 ]; then
		new_hardware=$2
		with_hardware=1
	fi
fi


if [ -z $new_board_name ]; then
	echo -n "" > $SHELL_PREV_DEFINE_SYS_FILE
	section_content_get $PREV_DEFINE_KEY $BOARD_INFO_SRC_FILE $SHELL_PREV_DEFINE_SYS_FILE

	for file in $SHELL_PREV_DEFINE_SYS_FILE
	do
		while read line
		do
			debug echo $line
			#依据获取到的key=value键值对  生成一个本地变量  以便后面对其进行引用
			eval $line
		done  < $file
	done

	echo "----------------current board define----------------"
	cat $SHELL_PREV_DEFINE_SYS_FILE

	echo "----------------change board define----------------"
	echo ""
	echo "step1:choose board name"

	while true
	do
		select var in "$skip_key" ${board_name_array[*]}; do
			break
		done

		if [ ! -z $var ]; then
			if [ $skip_key = $var ]; then
				new_board_name=$board_name
			else
				new_board_name=$var
			fi
			break;
		fi
	done
fi

echo ""
echo "new board name: $new_board_name"
boarddefine_get $new_board_name
new_board_type=${default_board_type}
echo "new board type: ${new_board_type}"
if [ $skip_key = $var ]; then
	default_hardware=$hardware
else
	default_hardware=${default_hardware_list[0]}
fi

if [ $manual_set -eq 1 ]; then
	if [ $with_hardware -eq 0 ]; then
		new_hardware=$default_hardware
	else
		index=0 
		#检查hardware参数是否正确
		for var in ${default_hardware_list[*]};
		do
			if [ $new_hardware = $var ]; then
				break
			fi
			index=$(($index+1))
		done
		if [ $index = ${#default_hardware_list[*]} ]; then
			echo "new hardware is invalid!  valid hardware:(${default_hardware_list[*]})"
			exit 1
		fi
	fi
else
	echo "defaule hardware: ${default_hardware}"
	echo ""
fi


if [ -z $new_hardware ]; then
	echo "step2:choose hardware"

	while true
	do
		select var in "$skip_key" ${default_hardware_list[*]}; do
			break
		done

		if [ ! -z $var ]; then
			if [ $skip_key = $var ]; then
				new_hardware=$default_hardware
			else
				new_hardware=$var
			fi
			echo ""
			break;
		fi
	done
fi

echo "new hardware: $new_hardware"

echo "------------write back new board define------------"

sed -i "/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/board_name=.*/board_name="${new_board_name}"/\
	;s/board_type=.*/board_type="${new_board_type}"/\
	;s/hardware=.*/hardware="${new_hardware}"/" $BOARD_INFO_SRC_FILE


#index=0
#while true
#do
#	if [ ${board_name_array[$index]} = ${board_name} ]; then
#		break;
#	fi
#	let "index = $index + 1"
#	if [ $index -ge ${#board_name_array[*]} ]; then
#		break
#	fi
#done
#
#if [ $index -ge ${#board_name_array[*]} ]; then
#	echo "$board_name is invalid!"
#	exit 3
#fi
#
#board_type=${board_type_array[$index]}
#echo "new board type: ${board_type}"
#echo ""
#echo "step2:choose hardware"

#echo "init hardware:${init_hardware_array[$index]}"
#while true
#do
#	read -p "enter new hardware:" hardware
#
#	if [ -z $hardware ]; then
#		hardware=${init_hardware_array[$index]}
#		break
#	fi
#	case "$hardware" in  
#		*[!0-9]* ) 
#			echo "invalid input! please input again"
#			continue
#		;;  
#		* ) 
#			break
#		;;
#	esac
#done
#
#echo "new hardware: $hardware"






