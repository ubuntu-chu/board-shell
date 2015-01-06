#!/bin/bash

boarddefine_utility_file="/etc/board/boarddefine-utility.sh"
if [ ! -e $boarddefine_utility_file ]; then
	echo "$boarddefine_utility_file  do not exist!"
	exit 1
fi
. $boarddefine_utility_file

DEBUG=0

boardname_define_file="/etc/board/rcS.board"
#板名表起始 结束标记
boardname_table_start="#boardname definition table -- start"
boardname_table_end="#boardname definition tabel -- end"
#暂时文件
boardname_file="/var/tmp/boardname_temp_file"

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

#新配置数组
new_config_array=()
#新配置数组索引
config_array_index=0
new_board_name=
assigned_board_name=
assigned_hardware=
show_current_board_define=0
new_board_type=
new_hardware=
board_name_changed=0
skip_key="skip"
config_none_key="config_none"

#数组索引
array_index=0
param_board_name="--board_name"
param_hardware="--hardware"
param_debug="--debug"
param_help="--help"
#info关键字 用于列出所有板名 和 对应的硬件版本号
param_info="--info"
param_current="--current"
#参数值数组
paramvalue_array=()
#参数key数组
paramkey_array=()

help(){
	echo "Usage            : $0 [$param_help|$param_current|$param_debug|$param_board_name|$param_hardware]"
	echo "Param $param_help: show help"
	echo "Param $param_info: show board name and relevant hardware list"
	echo "Param $param_current: show current board define"
	echo "Param $param_debug: enable debug"
	echo "Param $param_board_name : ${boardname_array[*]}"
	echo "Param $param_hardware   : "

	help_index=0
	#遍历获取硬件信息
	while :;
	do
		#获取此board_name所对应的硬件版本信息及配置信息
		hardwareinfo_get "${hardware_array[$help_index]}"
		echo "                   board_name: ${boardname_array[$help_index]}"
		echo "                   hardware={"
		echo "                       default_ver=${hardwarevalue_default}"

		inner_index=0
		while :;
		do
			echo "                       {"
			echo "                           hardware_ver=${hardwarevalue_array[$inner_index]}"
			hardwareconfig_get ${hardwareconfig_array[$inner_index]}
			#当前硬件版本下存在配置选项
			if [ ${#configname_array[*]} -ne 0 ]; then
				echo "                           config={"
				config_index=0
				while :;
				do
					if [ $config_index -ge ${#configname_array[*]} ]; then
						break
					fi
					echo "                               {"
					echo "                                   name=${configname_array[$config_index]}"
					echo "                                   default=${configdefault_array[$config_index]}"
					echo "                                   range=`echo ${configrange_array[$config_index]} | tr ':' ' '`"
					if [ $(($config_index+1)) -eq ${#configname_array[*]} ]; then
						echo "                               }"
					else
						echo "                               },"
					fi
					config_index=$(($config_index + 1))
				done

				echo "                           }"
			fi
			if [ $(($inner_index+1)) -eq ${#hardwarevalue_array[*]} ]; then
				echo "                       }"
			else
				echo "                       },"
			fi
			inner_index=$(($inner_index+1))
			if [ $inner_index -ge ${#hardwarevalue_array[*]} ]; then
				break
			fi
		done
		echo "                   }"
		echo ""
		help_index=$(($help_index+1))
		if [ $help_index -ge ${#boardname_array[*]} ]; then
			break
		fi
	done
	exit 1
}

info(){
	echo "$param_board_name : ${boardname_array[*]}"

	info_index=0
	#遍历获取硬件信息
	while :;
	do
		#获取此board_name所对应的硬件版本信息及配置信息
		hardwareinfo_get "${hardware_array[$info_index]}"
		echo "$param_hardware : ${boardname_array[$info_index]}-${hardwarevalue_array[*]}"
		info_index=$(($info_index+1))
		if [ $info_index -ge ${#boardname_array[*]} ]; then
			break
		fi
	done
	exit 1
}

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
			debug echo "$2 can not be found in array:$1"
			return 1
		fi
	done
	debug echo "array_index=$array_index"

	return 0
}

new_config_array_add()
{
	new_config_array[$config_array_index]="$1"
	config_array_index=$(($config_array_index + 1))
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
	debug echo "------------------------------------------"
	debug echo $list

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

#获取硬件版本配置详细信息
hardwareconfig_get()
{
	configname_array=()
	configdefault_array=()
	configrange_array=()

	list=`echo "$1" | tr ':' ' '`
	#判断硬件版本下面是否有配置
	if [ "$list" = "$config_none_key" ]; then
		return 1
	fi
	debug echo "------------------------------------------"

	index=0
	for var in $list
	do
		generate_var_from_file "${var}" "$boardname_define_file"
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
			generate_var_from_file "${define}" "$boardname_define_file"
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

	return 0
}


#生成boardname_file文件
sed -n "/^""${boardname_table_start}""/,/^""${boardname_table_end}""/ p"  $boardname_define_file \
	| sed '1d;2d;$d' | awk '{print $0 > "'"${boardname_file}"'"}'

#初始化相关数组
list=`sed -n "/^board_name \+board_type/ p"  $boardname_define_file` 
init_array "$list" title_array
debug echo title_array=${title_array[*]}

boarddefine_array_init "board_name" boardname_array
debug echo boardname_array=${boardname_array[*]}

boarddefine_array_init "board_type" boardtype_array
debug echo boardtype_array=${boardtype_array[*]}

boarddefine_array_init "hardware" hardware_array
debug echo hardware_array=${hardware_array[*]}

index=0
#解析所有参数
while [ $# -gt 0  ]; 
do    
	case "$1" in
		$param_debug)
			# 是 "-d" 或 "--debug" 参数?
			DEBUG=1
			;;
		$param_current)
			show_current_board_define=1
			;;
		$param_help)
			help
			;;
		$param_info)
			info
			;;
		$param_board_name)
			assigned_board_name="$2"
			shift
			;;
		$param_hardware)
			assigned_hardware="$2"
			shift
			;;
		--*)
			paramkey_array[$index]="$1"
			paramvalue_array[$index]="$2"
			index=$(($index + 1))
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

debug echo "paramkey_array=${paramkey_array[*]}"
debug echo "paramvalue_array=${paramvalue_array[*]}"


generate_var_from_file "${PREV_DEFINE_KEY}" "$BOARD_INFO_SRC_FILE"

echo "----------------current board define----------------"
#遍历数组 打印出当前板子定义信息
if [ ${#key_array[*]} -ne 0 ]; then
	index=0
	while :;
	do
		echo "${key_array[$index]}=${value_array[$index]}"
		index=$(($index + 1))
		if [ $index -ge ${#key_array[*]} ]; then
			break
		fi
	done
fi

if [ $show_current_board_define -eq 1 ]; then
	#当前环境支持板载定义配置
	if [ ${#key_array[*]} -ne 0 ]; then
		exit 0
	#不支持配置
	else
		exit 1
	fi
fi

echo "----------------change board define----------------"

if [ -z $assigned_board_name ]; then
	echo "step1:choose board name"
	echo "current board name: ${board_name}"

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
else 
	#检查设置的baord_name是否正确
	arrayindex_get boardname_array "$assigned_board_name"
	if [ $? -ne 0 ]; then
		echo "board name invalid! valid board name:${boardname_array[*]}"
		exit 1
	fi
	new_board_name=$assigned_board_name
fi

if [ $new_board_name = $board_name ]; then
	board_name_changed=0
else
	board_name_changed=1
fi
echo "new board name=$new_board_name"
new_config_array_add "board_name=$new_board_name"

#获取board_type
arrayindex_get boardname_array "$new_board_name"
new_board_type=${boardtype_array[$array_index]}
echo "new board type=${new_board_type}"
new_config_array_add "board_type=$new_board_type"

#获取硬件版本
hardwareinfo_get "${hardware_array[$array_index]}"

#未通过形参设置 hardware
if [ -z $assigned_hardware ]; then
	if [ $board_name_changed -eq 0 ]; then
		#使用当前版本
		default_hardware=$hardware
	else
		default_hardware=${hardwarevalue_default}
	fi
	if [ -z $assigned_board_name ]; then
		echo ""

		echo "step2:choose hardware"
		echo "current hardware: ${default_hardware}"
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
				break;
			else
				echo "input invalid! please input again!"
				continue
			fi
		done
	else
		new_hardware=$default_hardware
	fi
#通过形参设置 hardware
else
	#检查设置的hardware是否正确
	arrayindex_get hardwarevalue_array "$assigned_hardware"
	if [ $? -ne 0 ]; then
		echo "hardware invalid! valid hardware:${hardwarevalue_array[*]}"
		exit 1
	fi
	new_hardware=$assigned_hardware
fi

echo "new hardware=$new_hardware"
new_config_array_add "hardware=$new_hardware"
#判断所选择的硬件版本 在数组中的索引  使用此索引去查找此硬件版本对应的配置
arrayindex_get hardwarevalue_array "$new_hardware"
hardwareconfig_get ${hardwareconfig_array[$array_index]}

#配置部分
if [ ! -z "$assigned_board_name" ]; then
	#通过参数进行配置
	#判断是否有非法参数
	i=0
	configmatch_array=()
	#遍历数组 要判断key 和 value
	while :;
	do
		if [ $i -ge ${#paramkey_array[*]} ]; then
			break
		fi
		#key的值 去除--前缀
		key=`echo ${paramkey_array[$i]}|tr -d '-'`
		value=${paramvalue_array[$i]}
		index=0
		is_find=0
		while :;
		do
			if [ $index -ge ${#configname_array[*]} ]; then
				break
			fi
			#配置名称数组
			config_name=${configname_array[$index]}
			if [ "$key" = "$config_name" ]; then
				config_list=`echo ${configrange_array[$index]} | tr ':' ' '`
				#key值 相等   进一步判断value是否合法
				is_find=1
				debug echo "config_list=$config_list"
				#注意此时： for里面config_list的写法
				for config_var in $config_list;
				do
					debug  echo "value=$value"
					debug  "config_var=$config_var"
					#value 合法判断
					if [ "$value" = "$config_var" ]; then
						is_find=2
						configmatch_array[$i]="$index"
						break
					fi
				done
			fi
			index=$(($index + 1))
		done
		if [ $is_find -ne 2 ]; then
			if [ $is_find -eq 1 ]; then
				echo "$key=$value : $value invalid, please check!"
			else
				echo "$key=$value : $key invalid, please check!"
			fi
			exit 4	
		fi
		echo "new ${key}=${value}"
		new_config_array_add "${key}=${value}"
		i=$(($i + 1))
	done
	#判断传入的形参值是否已经全部配置完所有参数 对于尚未配置的参数 使用默认配置
	if [ ${#configmatch_array[*]} -ne ${#configname_array[*]} ]; then
		#遍历默认参数列表 
		index_list=`seq 0 $((${#configname_array[*]} - 1))`
		debug echo "index_list=$index_list"
		tr_list=`echo ${configmatch_array[*]} | tr -d ' '`
		debug echo "tr_list=$tr_list"
		if [ -z $tr_list ]; then
			#defaut_list="$index_list"
			defaut_list=`echo $index_list| tr '\n' ' '`
		else
			defaut_list=`echo $index_list | tr -d $tr_list`
		fi
		debug echo "default_list=$defaut_list"
		for defaut_value in $defaut_list;
		do
			new_config_array_add "${configname_array[$defaut_value]}=${configdefault_array[$defaut_value]}"
		done
	fi
else
#手动设置配置
    #当前硬件版本中存在配置选项
	if [ ${#configname_array[*]} -ne 0 ]; then
		echo ""
		echo "step3:choose configuration"

		index=0
		while :;
		do
			config_name=${configname_array[$index]}
			config_defalut_value=${configdefault_array[$index]}
			#目前config_type未使用
			config_type=${configtype_array[$index]}
			echo "config: ${config_name}"
			if [ $board_name_changed -eq 0 ]; then
				eval config_name_value=\$${config_name}
			else
				config_name_value="${config_defalut_value}"
			fi
			if [ -z $config_name_value ]; then
				echo "current value:null  use default value: ${config_defalut_value}"
			else
				echo "current value:$config_name_value"
			fi
			#echo "default value: ${config_defalut_value}"
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
				new_config_array_add "${config_name}=${new_config}"
			else
				echo "input invalid! please input again!"
				continue
			fi

			index=$(($index + 1))
			if [ $index -ge ${#configname_array[*]} ]; then
				break
			fi
		done
	fi
fi

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


value=`grep -n "${PREV_DEFINE_KEY}={"  $BOARD_INFO_SRC_FILE`
if [ $? -ne 0 ]; then
	echo "$BOARD_INFO_SRC_FILE donot have ${PREV_DEFINE_KEY} line"
	exit 1
fi
line_no=`echo $value|cut -d ':' -f1`

debug echo "match line no = $line_no"
line_no=$(($line_no-1))

#将原先的区段删除   再在指定的位置上 添加新的定义
sed -i "/^"${PREV_DEFINE_KEY}"={/,/^\}/ d\
		;"${line_no}" r "${temp_file}"" $BOARD_INFO_SRC_FILE


#删除临时文件
rm -rf $temp_file
rm -rf $boardname_file

echo "execute </etc/board/cpu-identify.sh start> to update boardinfo file"
/etc/board/cpu-identify.sh start > /dev/null

