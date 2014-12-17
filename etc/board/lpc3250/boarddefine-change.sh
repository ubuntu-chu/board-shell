#!/bin/bash

. /etc/board/rcS

board_name_array=($BOARD_NAME_RFU_RRU $BOARD_NAME_CS_RFU_RRU $BOARD_NAME_SS_RFU_RRU $BOARD_NAME_IFU_CCU $BOARD_NAME_RS_CCU)
board_type_array=(1000 1001 1002 2000 2001)
init_hardware_array=(3 1 1 1 1)

echo -n "" > $SHELL_PREV_DEFINE_SYS_FILE
section_content_get $PREV_DEFINE_KEY $BOARD_INFO_SRC_FILE $SHELL_PREV_DEFINE_SYS_FILE

echo "----------------current board define----------------"
cat $SHELL_PREV_DEFINE_SYS_FILE

#判断数组内元素个数是否相同
if [ ${#board_name_array[*]} -ne ${#init_hardware_array[*]} ]; then
	echo "board_name_array cnts != init_hardware_array cnts!"
	exit 1
fi

if [ ${#board_name_array[*]} -ne ${#board_type_array[*]} ]; then
	echo "board_name_array cnts != board_type_array cnts!"
	exit 3
fi

echo "----------------change board define----------------"
echo ""
echo "step1:choose board name"

while true
do
	select board_name in ${board_name_array[*]}; do
		break
	done

	if [ ! -z $board_name ]; then
		echo "new board name: $board_name"
		break;
	fi
done

index=0
while true
do
	if [ ${board_name_array[$index]} = ${board_name} ]; then
		break;
	fi
	let "index = $index + 1"
	if [ $index -ge ${#board_name_array[*]} ]; then
		break
	fi
done

if [ $index -ge ${#board_name_array[*]} ]; then
	echo "$board_name is invalid!"
	exit 3
fi

board_type=${board_type_array[$index]}
echo "new board type: ${board_type}"
echo ""
echo "step2:choose hardware"

echo "init hardware:${init_hardware_array[$index]}"
while true
do
	read -p "enter new hardware:" hardware

	if [ -z $hardware ]; then
		hardware=${init_hardware_array[$index]}
		break
	fi
	case "$hardware" in  
		*[!0-9]* ) 
			echo "invalid input! please input again"
			continue
		;;  
		* ) 
			break
		;;
	esac
done

echo "new hardware: $hardware"

echo "------------write back new board define------------"

sed -i "/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/board_name=.*/board_name="${board_name}"/\
	;s/board_type=.*/board_type="${board_type}"/\
	;s/hardware=.*/hardware="${hardware}"/" $BOARD_INFO_SRC_FILE






