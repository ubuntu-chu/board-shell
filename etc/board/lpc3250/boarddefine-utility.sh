#!/bin/bash

if [ -e /etc/board/rcS ]; then
	. /etc/board/rcS
fi

DEBUG=1

boardname_define_file=/etc/board/rcS.board_new
boardname_table_start="#boardname definition table -- start"
boardname_table_end="#boardname definition tabel -- end"

boardname_file="./boardname"

title_array=()
boardname_array=()
boardtype_array=()
hardware_array=()

hardwarevalue_array=()
hardwarevalue_default=
hardwareconfig_array=()

configname_array=()
configdefault_array=()
configrange_array=()
configtype_array=()

#键数组
key_array=()
#值数组
value_array=()

new_config_list=
new_config_array=()
config_array_index=0
new_board_name=
new_board_type=
new_hardware=
skip_key="skip"

array_index=0

#由hardware链表开始查找 建立函数  依次可找到所有配置  配置要有类型 方便进行不同的解析


init_array()
{
	index=0
	for i in $1
	do
		eval $2[$index]="$i"
		index=$(($index+1))
	done
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
			echo "$2 can not be found in array:$1"
			return 1
		fi
	done
	debug echo "array_index=$array_index"

	return 0
}

file_lines_proc()
{
	#去除首部 尾部的空格  以及=号前后的空格
	#将空格替换为_
	sed -i "s/^[[:space:]]*//;s/ *= */=/;s/[[:space:]]*$//;s/[[:space:]]/_/g" $1
}

boarddefine_array_init()
{
	arrayindex_get title_array "$1"

	#转化为awk格式
	array_index=$(($array_index + 1))
	list=`cat $boardname_file| awk '{print $"'${array_index}'"}' | tr '\n' ' '`
	init_array "$list" "$2"
}


#获取硬件版本信息
hardwareinfo_get()
{
	hardwarevalue_array=()
	hardwarevalue_default=
	hardwareconfig_array=()

	list=`echo "$1" | tr ':' ' '`
	temp_file="temp"
	echo "------------------------------------------"
	echo $list

	index=0
	for var in $list
	do
		#debug echo $var
		sed -n "/^""${var}""={/,/^}/ p"  $boardname_define_file \
			| sed '1d;$d' | awk '{print $0 > "'"${temp_file}"'"}'
		file_lines_proc $temp_file
		#debug cat $temp_file
 		while read line
 		do
 			#debug echo $line
 			#依据获取到的key=value键值对  生成一个本地变量  以便后面对其进行引用
 			eval $line
 		done  < $temp_file

		hardwarevalue_array[$index]=$value
		if [ $default = "yes" ]; then
			if [ -z $hardwarevalue_default ]; then
				hardwarevalue_default=$value
			else
				echo "hardware list have two or more defaule value"
				exit 1
			fi
		fi
		hardwareconfig_array[$index]=$config
		index=$(($index+1))
	done

	debug echo "hardwarevalue_array=${hardwarevalue_array[*]}"
	debug echo "hardwarevalue_default=${hardwarevalue_default}"
	debug echo "hardwareconfig_array=${hardwareconfig_array[*]}"
}

generate_var_from_file()
{
	#键数组
	key_array=()
	#值数组
	value_array=()

	sed -n "/^""${1}""={/,/^}/ p"  $boardname_define_file \
		| sed '1d;$d' | awk '{print $0 > "'"${temp_file}"'"}'
	file_lines_proc $temp_file
	#debug cat $temp_file
	generate_var_from_file_index=0
	while read line
	do
		#debug echo $line
		#依据获取到的key=value键值对  生成一个本地变量  以便后面对其进行引用
		eval $line
		#debug echo "line = $line"
		key_array[$generate_var_from_file_index]=`echo $line|cut -d '=' -f 1`
		value_array[$generate_var_from_file_index]=`echo $line|cut -d '=' -f 2`
		generate_var_from_file_index=$(($generate_var_from_file_index + 1))
	done  < $temp_file

	#debug echo ${key_array[*]}
	#debug echo ${value_array[*]}
}

#获取硬件版本配置详细信息
hardwareconfig_get()
{
	configname_array=()
	configdefault_array=()
	configrange_array=()

	list=`echo "$1" | tr ':' ' '`
	#debug echo "list=$list"
	temp_file="temp"
	echo "------------------------------------------"
	echo $config_list

	index=0
	for var in $list
	do
		generate_var_from_file "${var}"
		if [ -z $default ]; then
			echo "config:$var  key[default] value undefined"
			exit 1
		else
			configdefault_array[$index]=$default
		fi

		if [ -z $define ]; then
			echo "config:$var  key[define] value undefined"
			exit 1
		else
			generate_var_from_file "${define}"
		fi

		if [ -z $name ]; then
			echo "config:$var  key[name] value undefined"
			exit 1
		else
			configname_array[$index]=$name
		fi
		if [ -z $range ]; then
			echo "config:$var  key[range] value undefined"
			exit 1
		else
			configrange_array[$index]=$range
		fi
		if [ -z $type ]; then
			echo "config:$var  key[type] value undefined"
			exit 1
		else
			configtype_array[$index]=$type
		fi
		index=$(($index+1))
	done

	debug echo "configname_array=${configname_array[*]}"
	debug echo "configdefault_array=${configdefault_array[*]}"
	debug echo "configrange_array=${configrange_array[*]}"
}


#| awk '{print $0 > "'"${boardname_file}"'"}'

#sed -n "/^""${boardname_table_start}""/,/^""${boardname_table_end}""/ p"  $boardname_define_file \
#	| sed '1d;2d;$d' | awk '{print $0 > "'"${boardname_file}"'"}'
#

list=`sed -n "/^board_name \+board_type/ p"  $boardname_define_file` 
init_array "$list" title_array
debug echo title_array=${title_array[*]}

boarddefine_array_init "board_name" boardname_array
debug echo boardname_array=${boardname_array[*]}

boarddefine_array_init "board_type" boardtype_array
debug echo boardtype_array=${boardtype_array[*]}

boarddefine_array_init "hardware" hardware_array
debug echo hardware_array=${hardware_array[*]}


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
		select var in "$skip_key" ${boardname_array[*]}; do
			break
		done

		if [ ! -z $var ]; then
			if [ $skip_key = $var ]; then
				new_board_name=$board_name
			else
				new_board_name=$var
			fi
			break;
		else
			echo "input invalid! please input again!"
			continue
		fi
	done
fi

echo ""
echo "new board name: $new_board_name"
new_config_array[$config_array_index]="board_name=$new_board_name"
config_array_index=$(($config_array_index + 1))

#获取board_type
arrayindex_get boardname_array "$new_board_name"
new_board_type=${boardtype_array[$array_index]}
echo "new board type: ${new_board_type}"
new_config_array[$config_array_index]="board_type=$new_board_type"
config_array_index=$(($config_array_index + 1))


#获取硬件版本
hardwareinfo_get "${hardware_array[$array_index]}"
if [ $skip_key = $var ]; then
	default_hardware=$hardware
else
	default_hardware=${hardwarevalue_default}
fi

echo "current hardware: ${default_hardware}"

echo "step2:choose hardware"
while true
do
	select var in "$skip_key" ${hardwarevalue_array[*]}; do
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
	else
		echo "input invalid! please input again!"
		continue
	fi
done

echo "new hardware: $new_hardware"
new_config_array[$config_array_index]="hardware=$new_hardware"
config_array_index=$(($config_array_index + 1))

echo "step3:choose configuration"
#判断所选择的硬件版本 在数组中的索引  使用此索引去查找此硬件版本对应的配置
arrayindex_get hardwarevalue_array "$new_hardware"
hardwareconfig_get ${hardwareconfig_array[$array_index]}

index=0
	while :;
	do
		config_name=${configname_array[$index]}
		config_defalut_value=${configdefault_array[$index]}
		#目前config_type未使用
		config_type=${configtype_array[$index]}
		echo "config: ${config_name}"
		echo "default value: ${config_defalut_value}"
		config_list=`echo ${configrange_array[$index]} | tr ':' ' '`

		select var in "$skip_key" ${config_list}; do
			break
		done

		if [ ! -z $var ]; then
			debug set -x
			if [ $skip_key = $var ]; then
				eval config_current_value=\$${config_name}
				if [ -z $config_current_value ]; then
					new_config=${config_defalut_value}
				else
					new_config=${config_current_value}
				fi
			else
				new_config=$var
			fi
			debug set +x
			echo "new value: $new_config"
			echo ""
			new_config_array[$config_array_index]="${config_name}=${new_config}"
			config_array_index=$(($config_array_index + 1))
		else
			echo "input invalid! please input again!"
			continue
		fi

		index=$(($index + 1))
		if [ $index -ge ${#configname_array[*]} ]; then
			break
		fi
	done


#echo "new_config_list=${new_config_list}"

echo "-----------------new board define------------------"
echo "${PREV_DEFINE_KEY}={" > $temp_file

index=0
while :;
do
	config=${new_config_array[$index]}
	echo $config
	echo "    $config" >> $temp_file

	index=$(($index + 1))
	if [ $index -ge ${#new_config_array[*]} ]; then
		break
	fi
done
echo "}" >> $temp_file

#测试使用
#hardwareconfig_get "${hardwareconfig_array[*]}"
#hardwareinfo_get "${hardware_array[1]}"

DEST_BOARD_INFO_FILE=$BOARD_INFO_SRC_FILE

value=`grep -n "${PREV_DEFINE_KEY}={"  $DEST_BOARD_INFO_FILE`
if [ $? -ne 0 ]; then
	echo "$DEST_BOARD_INFO_FILE donot have ${PREV_DEFINE_KEY} line"
	exit 1
fi
line_no=`echo $value|cut -d ':' -f1`

debug echo "match line no = $line_no"
line_no=$(($line_no-1))

#将原先的区段删除   再在指定的位置上 添加新的定义
sed -i "/^"${PREV_DEFINE_KEY}"={/,/^\}/ d\
		;"${line_no}" r "${temp_file}"" $DEST_BOARD_INFO_FILE


rm -rf $temp_file







#sed -i "/^"${boardname_table_start}",/^"${boardname_table_end}"/ s/board_name=.*/board_name="${new_board_name}"/\
#	;/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/board_type=.*/board_type="${new_board_type}"/\
#	;/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/hardware=.*/hardware="${new_hardware}"/" $DEST_BOARD_INFO_FILE
#new_board_name=
#new_board_type=
#new_hardware=
#skip_key="skip"
#manual_set=0
#with_hardware=0
#
#
#help(){
#	echo "Usage                 : $0 [board_name] [hardware]"
#	echo "Param board_name      : ${board_name_array[*]}"
#	echo "Param hardware        : "
#	for name in ${board_name_array[*]};
#	do
#		boarddefine_get $name
#		echo "                        $name - (${default_hardware_list[*]})"
#	done
#	exit 1
#
#}
#
#if [ $# -ge 1 ]; then
#
#	if [ $1 = "help" ]; then
#		help
#	else
#		echo "-------------manual change board define------------"
#		manual_set=1
#		new_board_name=$1
#		var=$new_board_name
#	fi
#	if [ $# -eq 2 ]; then
#		new_hardware=$2
#		with_hardware=1
#	fi
#fi
#
#
#if [ -z $new_board_name ]; then
#	echo -n "" > $SHELL_PREV_DEFINE_SYS_FILE
#	section_content_get $PREV_DEFINE_KEY $BOARD_INFO_SRC_FILE $SHELL_PREV_DEFINE_SYS_FILE
#
#	for file in $SHELL_PREV_DEFINE_SYS_FILE
#	do
#		while read line
#		do
#			debug echo $line
#			#依据获取到的key=value键值对  生成一个本地变量  以便后面对其进行引用
#			eval $line
#		done  < $file
#	done
#
#	echo "----------------current board define----------------"
#	cat $SHELL_PREV_DEFINE_SYS_FILE
#
#	echo "----------------change board define----------------"
#	echo ""
#	echo "step1:choose board name"
#
#	while true
#	do
#		select var in "$skip_key" ${board_name_array[*]}; do
#			break
#		done
#
#		if [ ! -z $var ]; then
#			if [ $skip_key = $var ]; then
#				new_board_name=$board_name
#			else
#				new_board_name=$var
#			fi
#			break;
#		fi
#	done
#fi
#
#echo ""
#echo "new board name: $new_board_name"
#boarddefine_get $new_board_name
#new_board_type=${default_board_type}
#echo "new board type: ${new_board_type}"
#if [ $skip_key = $var ]; then
#	default_hardware=$hardware
#else
#	default_hardware=${default_hardware_list[0]}
#fi
#
#if [ $manual_set -eq 1 ]; then
#	if [ $with_hardware -eq 0 ]; then
#		new_hardware=$default_hardware
#	else
#		index=0 
#		#检查hardware参数是否正确
#		for var in ${default_hardware_list[*]};
#		do
#			if [ $new_hardware = $var ]; then
#				break
#			fi
#			index=$(($index+1))
#		done
#		if [ $index = ${#default_hardware_list[*]} ]; then
#			echo "new hardware is invalid!  valid hardware:(${default_hardware_list[*]})"
#			exit 1
#		fi
#	fi
#else
#	echo "defaule hardware: ${default_hardware}"
#	echo ""
#fi
#
#
#if [ -z $new_hardware ]; then
#	echo "step2:choose hardware"
#
#	while true
#	do
#		select var in "$skip_key" ${default_hardware_list[*]}; do
#			break
#		done
#
#		if [ ! -z $var ]; then
#			if [ $skip_key = $var ]; then
#				new_hardware=$default_hardware
#			else
#				new_hardware=$var
#			fi
#			echo ""
#			break;
#		fi
#	done
#fi
#
#echo "new hardware: $new_hardware"
#
#echo "------------write back new board define------------"
#
#if [ $# -eq 3 ]; then
#	DEST_BOARD_INFO_FILE=$3
#else
#	DEST_BOARD_INFO_FILE=$BOARD_INFO_SRC_FILE
#fi
#
#
#sed -i "/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/board_name=.*/board_name="${new_board_name}"/\
#	;/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/board_type=.*/board_type="${new_board_type}"/\
#	;/^"${PREV_DEFINE_KEY}"={/,/^\}/ s/hardware=.*/hardware="${new_hardware}"/" $DEST_BOARD_INFO_FILE
#
#
##index=0
##while true
##do
##	if [ ${board_name_array[$index]} = ${board_name} ]; then
##		break;
##	fi
##	let "index = $index + 1"
##	if [ $index -ge ${#board_name_array[*]} ]; then
##		break
##	fi
##done
##
##if [ $index -ge ${#board_name_array[*]} ]; then
##	echo "$board_name is invalid!"
##	exit 3
##fi
##
##board_type=${board_type_array[$index]}
##echo "new board type: ${board_type}"
##echo ""
##echo "step2:choose hardware"
#
##echo "init hardware:${init_hardware_array[$index]}"
##while true
##do
##	read -p "enter new hardware:" hardware
##
##	if [ -z $hardware ]; then
##		hardware=${init_hardware_array[$index]}
##		break
##	fi
##	case "$hardware" in  
##		*[!0-9]* ) 
##			echo "invalid input! please input again"
##			continue
##		;;  
##		* ) 
##			break
##		;;
##	esac
##done
##
##echo "new hardware: $hardware"
#
#
#
#
#
#
