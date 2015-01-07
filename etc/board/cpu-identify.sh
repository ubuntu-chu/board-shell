#!/bin/bash
#

. /etc/board/rcS
. /etc/board/configuration-parse.sh

#保存从gpio读取的值  使用数组   注意：此处时bash的语法格式  因此此脚本在执行时 需要用Bash来执行
CPU_ID_ARRAY=()
#声明并定义关联数组
declare -a PIN_DIR_MAP=()
CPU_ID_PIN_ARRAY=()
SYS_CLASS_GPIO_FILE_ARRAY=()
#若所有的BOARD_ID都为0时 代表此应用不支持槽位号  即整个应用中只有一块主板 
BOARD_ID=$BOARD_ID_NONE_TEXT
SYS_REGS_EXIST=0

app_define_files_add()
{
	#获取应用中定义的priv文件
	if [ -x ${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS ]; then
		${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS "$1" "$2"
	fi

	debug echo "shift before \$@ = $@"
	shift
	shift
	debug echo "shift after \$@ = $@"

	for file in $@
	do
		file_lines_proc $file

		while read line
		do
			debug echo $line
			echo "    $line" >> $BOARD_INFO_FILE
		done  < $file
	done
}

#cpu 信息处理函数
#形  参:
#        $1    board_id
#        $2    cpu_id
#返回值：
#        信息成功处理 返回0
#        否则 返回非0值
cpu_identify_proc(){
	#依据 board_id 和 cpu_id 查找 boardinfo definition table
	#使用双引号 代表使用字符串匹配
	#value=`awk '{if ($1 == "'"${1}"'" && $2 == "'"${2}"'"){print $0}}' $BOARD_INFO_SRC_FILE`
	#不使用双引号  代表使用数字匹配
	value=`awk '{if ($1 == "'"${1}"'" && $2 == "'"${2}"'"){print $0}}' $BOARD_INFO_SRC_FILE`
	#判断是否查找到
	if [ -z "$value" ]; then
		#使用数字匹配 board_id
		value=`awk '{if ($1 == '${1}' && $2 == '${2}'){print $0}}' $BOARD_INFO_SRC_FILE`
		if [ -z "$value" ]; then
			echo "$BOARD_INFO_SRC_FILE boardinfo definition has no item line: board_id = ${1}  cpu_id = ${2}!"
			return 1
		fi
	fi

	#注意： 此处是字符串匹配 注意"'"${BOARD_ID_KEY}"'"的写法
	item=`awk '{if ($1 == "'"${BOARD_ID_KEY}"'" && $2 == "'"${CPU_ID_KEY}"'"){print $0}}' $BOARD_INFO_SRC_FILE`
	if [ -z "$item" ]; then
		echo "$BOARD_INFO_SRC_FILE boardinfo definition table has no title line: ${BOARD_ID_KEY} ${CPU_ID_KEY}!"
		return 2
	fi

	index=0
	value_array=()
	item_array=()

	for i in ${value}
	do 
		value_array[$index]=${i}
		let "index = $index + 1"
	done

	index=0
	for i in ${item}
	do 
		item_array[$index]=${i}
		let "index = $index + 1"
	done

	if [ ${#value_array[*]} -ne ${#item_array[*]} ]; then
		echo "$BOARD_INFO_SRC_FILE format error!"
		echo "mapping table title cnts != value cnts"
		return 3
	fi

	echo "basic={" >> $BOARD_INFO_FILE
	index=0
	while true
	do
		#将除proc之外的列写入到$BOARD_INFO_FILE
		if [ ${item_array[$index]} != ${PRIV_KEY} -a ${item_array[$index]} != ${PROC_KEY} -a  ${item_array[$index]} != ${NETWORK_KEY} ]; then
			#将数组中的内容写入到文件中
			echo "    ${item_array[$index]}=${value_array[$index]}" >> $BOARD_INFO_FILE
		else 
			if [ ${item_array[$index]} = ${NETWORK_KEY} ]; then
				#记录network列的索引
				network_index=$index
			else 
				if [ ${item_array[$index]} = ${PRIV_KEY} ]; then
					#记录priv列的索引
					priv_index=$index
				else
					#记录proc列的索引
					proc_index=$index
				fi
			fi
		fi
		let "index = $index + 1"
		if [ $index -ge ${#value_array[*]} ]; then
			break
		fi
	done

	echo "}" >> $BOARD_INFO_FILE

	#写入网络配置信息
	echo "${NETWORK_KEY}={" >> $BOARD_INFO_FILE
	network_value=${value_array[$network_index]}
	awk '/^'${network_value}'=\{/,/^\}/ {print $0}' "${BOARD_INFO_SRC_FILE}"\
		| sed '1d;s/^[[:space:]]*//' | sed '1,$ s/^/    /' | sed '$ s/^[[:space:]]*//' \
		| awk '{print $0 >> "'"${BOARD_INFO_FILE}"'"}'

	#更改网卡mac地址信息中的oui和entity信息
	proc_line $MAC_OUI_KEY $BOARD_INFO_SRC_FILE
	mac_oui=${PROC_LINE_VALUE}

	#获取mac_batch_seq
	#判断mac_batch_seq来源
	if [ $MAC_BATCH_SEQ_SOURCE -eq $MAC_BATCH_SEQ_SOURCE_DEFINE ]; then
		proc_line $MAC_BATCH_SEQ_KEY $BOARD_INFO_SRC_FILE
		mac_batch_seq=${PROC_LINE_VALUE}
	else
		#从系统命令行中获取
		proc_cmdline_value $MAC_BATCH_SEQ_KEY 
		if [ $? -ne 0 ]; then
			exit 3
		fi
		mac_batch_seq=$PROC_LINE_VALUE
	fi
	
	#获取mac_board_id
	if [ ${1} = $BOARD_ID_NONE_TEXT ]; then
		mac_board_id=ff
	else
		mac_board_id=`printf "%02x" ${1}`
	fi
	#获取mac_cpu_id
	if [ ${2} = $CPU_ID_NONE_TEXT ]; then
		#这里等于00的原因在于 若值等于0f  则会发生
		#mac_lowest=0+0f: value too great for base (error token is "0f") 的错误
		mac_cpu_id="0f"
		mac_cpu_id_calc="00"
	else
		mac_cpu_id=`printf "%02x" ${2}`
		mac_cpu_id_calc=$mac_cpu_id
	fi
	#获取匹配的行号
	replace_nu_list=`egrep "${MAC_HWADDRESS_KEY} +${MAC_VALUE_KEY}*" -n ${BOARD_INFO_FILE}|cut -d ':' -f 0`
	debug echo "replace_nu_list = $replace_nu_list"
	mac_nic=0
	for i in $replace_nu_list;
	do 
		mac_lowest=$(($mac_nic+$mac_cpu_id_calc))
		#let "mac_lowest=$mac_nic+$mac_cpu_id_calc"
		if [ ${2} = $CPU_ID_NONE_TEXT ]; then
			let "mac_lowest=$mac_lowest | 0x0f"
		fi
		mac_lowest=`printf "%02x" ${mac_lowest}`
		#sed -ie ''${i}'s/'${MAC_HWADDRESS_KEY}' \+'${MAC_VALUE_KEY}'.*/'${MAC_HWADDRESS_KEY}' '${mac_oui}':'${mac_batch_seq}':'${mac_board_id}':'${mac_lowest}'/g' ${BOARD_INFO_FILE}
		sed -ie "${i}s/${MAC_HWADDRESS_KEY} \+${MAC_VALUE_KEY}.*/${MAC_HWADDRESS_KEY} ${mac_oui}:${mac_batch_seq}:${mac_board_id}:${mac_lowest}/g" ${BOARD_INFO_FILE}
		#对于多块网卡  mac地址最低字节的高四位不同 最多可支持16个网卡
		mac_nic=$(($mac_nic + 0x10))
	done

	#判断是否为恢复时所用根文件系统
	#从系统命令行中获取
	proc_cmdline_value $RECOVERY_KEY 
	if [ $? -eq 0 ]; then
		value=$PROC_LINE_VALUE
		if [ $value -eq 1 ]; then
			#修改主机名
			item_key=$HOSTNAME_KEY
			item=`grep -E "^ *\<${item_key}\>" $BOARD_INFO_FILE`
			if [ ! -z "$item" ]; then
				#在行尾添加-recovery
				sed -i -e 's/^ *\<'${item_key}'\>.*/&-recovery/' $BOARD_INFO_FILE
			fi

		fi
	fi

	#若系统寄存器存在  则解析系统寄存器 并将解析后的信息写入$BOARD_INFO_FILE文件中
	if [ $SYS_REGS_EXIST -eq 1 ]; then
		configuration_parse "all" $SHELL_COMM_FILE $BOARD_INFO_FILE
	fi


	#处理proc列字段
	proc_value=${value_array[$proc_index]}
	proc_key=${item_array[$proc_index]}
	if [ ! ${proc_value} = $PROC_NONE_VALUE ]; then
		echo "${proc_key}={" >> $BOARD_INFO_FILE

		#tee命令  从标准输入中读取并同时写入到标准输出和指定的文件上
		#-a,--append:不覆盖，而是追加输出到指定的文件中
		#proc_content=`awk '/^'${proc_value}'=\{/,/^\}/ {print $0}' "${BOARD_INFO_SRC_FILE}"\
		#	| sed '1d;$d;s/^[[:space:]]*//' | sed '1,$ s/^/    /;s/ *= \+\(\w\)/=\1/'\
		#	| awk '{print $0}' | tee -a ${BOARD_INFO_FILE}`
		#debug echo "before proc_content=$proc_content"
		#proc_content=`echo $proc_content|tr -d "{}"| tr -s " "| tr " " ":"|sed 's/:$//'`

		echo -n "" > $SHELL_PROC_SYS_FILE	
		echo -n "" > $SHELL_PROC_FILE
		section_content_get $proc_value $BOARD_INFO_SRC_FILE $SHELL_PROC_SYS_FILE
		#获取应用中定义的proc文件
		if [ -x ${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS ]; then
			${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS proc $SHELL_PROC_FILE
		fi
		first_add=0
		for file in $SHELL_PROC_SYS_FILE $SHELL_PROC_FILE
		do
			file_lines_proc $file

			while read line
			do
				debug echo $line

				eval line_content=$line
				if [ $first_add -eq 0 ]; then
					#处理可能存在的变量引用
					proc_content=$line_content
					first_add=1
				else
					#处理可能存在的变量引用
					#若proc_content中含有空格 则if [ -z $proc_content ]语句判断失效
					proc_content="$proc_content":$line_content
				fi
				echo "    $line_content" >> $BOARD_INFO_FILE
			done  < $file
		done
		debug echo "proc_content=$proc_content"
		#判断内核当前是否已经加载了此内核模块 若已加载 则先卸载
		#删除可能存在的双引号
		PROC_MODULE=`echo $PROC_MODULE|tr -d \"`
		lsmod|grep "${PROC_MODULE}" > /dev/null
		if [ $? -eq 0 ]; then
			rmmod $BOARD_ENTRY_SHELL_PATH/${PROC_MODULE}
		fi
		insmod $BOARD_ENTRY_SHELL_PATH/${PROC_MODULE}.ko proc_dir=${COMPANY} files_list=${proc_content}
		echo "}" >> $BOARD_INFO_FILE
	fi

	#处理priv列字段
	priv_value=${value_array[$priv_index]}
	priv_key=${item_array[$priv_index]}
	if [ ! ${priv_value} = $PRIV_NONE_VALUE ]; then
		echo "${priv_key}={" >> $BOARD_INFO_FILE

		echo -n "" > $SHELL_PRIV_SYS_FILE	
		echo -n "" > $SHELL_PRIV_FILE
		section_content_get $priv_value $BOARD_INFO_SRC_FILE $SHELL_PRIV_SYS_FILE

		#获取应用中定义的priv文件
		app_define_files_add "priv" "$SHELL_PRIV_FILE" "$SHELL_PRIV_SYS_FILE" "$SHELL_PRIV_FILE"
		echo "}" >> $BOARD_INFO_FILE
	fi

	#加入debug信息
	echo "debug={" >> $BOARD_INFO_FILE

	echo "    $BOARD_ID_FORCE_VALUE_KEY=$BOARD_ID_FORCE_VALUE" >> $BOARD_INFO_FILE
	if [ $BOARD_ID_SOURCE -eq $BOARD_ID_SOURCE_BOARD ]; then
		echo "    board_id_source=board_id_source_board" >> $BOARD_INFO_FILE
	else
		echo "    board_id_source=board_id_source_cmdline" >> $BOARD_INFO_FILE
	fi

	echo "    $CPU_ID_FORCE_VALUE_KEY=$CPU_ID_FORCE_VALUE" >> $BOARD_INFO_FILE
	if [ $CPU_ID_SOURCE -eq $CPU_ID_SOURCE_GPIO ]; then
		echo "    cpu_id_source=cpu_id_source_gpio" >> $BOARD_INFO_FILE
	else
		echo "    cpu_id_source=cpu_id_source_cmdline" >> $BOARD_INFO_FILE
	fi

	if [ $MAC_BATCH_SEQ_SOURCE -eq $MAC_BATCH_SEQ_SOURCE_DEFINE ]; then
		echo "    mac_batch_seq_source=mac_batch_seq_source_define" >> $BOARD_INFO_FILE
	else
		echo "    mac_batch_seq_source=mac_batch_seq_source_cmdline" >> $BOARD_INFO_FILE
	fi
	echo "    mac_rule={mac_oui(one byte):mac_batch(two bytes):mac_seq(one byte):mac_board_id(one byte):mac_lowest(one byte)}" >> $BOARD_INFO_FILE
	echo "    mac_board_id_rule={when board_id != none, mac_board_id = board_id. otherwise mac_board_id = ff}" >> $BOARD_INFO_FILE
	echo "    mac_lowest_rule={mac_nic(high 4 bits)|mac_cpu_id(low 4 bits)}" >> $BOARD_INFO_FILE
	echo "    mac_nic_rule={the initial value is 00, each NIC increase 10}" >> $BOARD_INFO_FILE
	echo "    mac_cpu_id_rule={mac_cpu_id = cpu_id}" >> $BOARD_INFO_FILE
	echo "    mac_oui=$mac_oui" >> $BOARD_INFO_FILE
	echo "    mac_batch_seq=$mac_batch_seq" >> $BOARD_INFO_FILE
	echo "    mac_board_id=$mac_board_id" >> $BOARD_INFO_FILE
	echo "    mac_cpu_id=$mac_cpu_id" >> $BOARD_INFO_FILE
	echo "    ${NETWORK_KEY}=$network_value" >> $BOARD_INFO_FILE
	echo "    ${proc_key}=${proc_value}" >> $BOARD_INFO_FILE
	echo "    ${priv_key}=${priv_value}" >> $BOARD_INFO_FILE
	echo "    etc_board_shell_version=${VERSION}" >> $BOARD_INFO_FILE

	#添加bootloader版本信息
	proc_cmdline_value $BOOTLOADER_VER_KEY 
	if [ $? -eq 0 ]; then
		echo "    bootloader_version=${PROC_LINE_VALUE}" >> $BOARD_INFO_FILE
	fi
	#添加kernel版本信息
	#判断是否存在内核版本文件
	kerenl_version=
	if [ -r $PROC_KERN_VER_FILE ]; then
		kerenl_version="`cat $PROC_KERN_VER_FILE`_" 
	fi
	uname_content=`uname -a`
	kerenl_version=$kerenl_version"`echo $uname_content|cut -d ' ' -f 11`-"
	kerenl_version=$kerenl_version"`echo $uname_content|cut -d ' ' -f 7`-"
	kerenl_version=$kerenl_version"`echo $uname_content|cut -d ' ' -f 8`_"
	kerenl_version=$kerenl_version"`echo $uname_content|cut -d ' ' -f 9`_"
	kerenl_version=$kerenl_version"`echo $uname_content|cut -d ' ' -f 3`"
	echo "    kernel_version=${kerenl_version}" >> $BOARD_INFO_FILE
	#get item line
	build_time=`grep -E "^\<${BUILD_TIME_KEY}\>" $BOARD_INFO_SRC_FILE`
	if [ ! -z "$build_time" ]; then
		echo "    $build_time" >> $BOARD_INFO_FILE
	fi
	#获取应用中定义的debug文件
	echo -n "" > $SHELL_DEBUG_FILE
	app_define_files_add "debug" "$SHELL_DEBUG_FILE" "$SHELL_DEBUG_FILE"

	echo "}" >> $BOARD_INFO_FILE
	

	return 0
}

if [ ! "$1" = "start" ]; then
	exit 0
fi

echo "Starting cpu identify..." 

echo "************board info definition************" > $BOARD_INFO_FILE
echo "" >> $BOARD_INFO_FILE

proc_line_return $PREV_DEFINE_KEY $BOARD_INFO_SRC_FILE

if [ $? -eq 0 ]; then

	echo "$PREV_DEFINE_KEY={" >> $BOARD_INFO_FILE

	echo -n "" > $SHELL_PREV_DEFINE_SYS_FILE
	section_content_get $PREV_DEFINE_KEY $BOARD_INFO_SRC_FILE $SHELL_PREV_DEFINE_SYS_FILE

	for file in $SHELL_PREV_DEFINE_SYS_FILE
	do
		file_lines_proc $file

		while read line
		do
			debug echo $line
			#依据获取到的key=value键值对  生成一个本地变量  以便后面对其进行引用
			eval $line
			echo "    $line" >> $BOARD_INFO_FILE
		done  < $file
	done
	echo "}" >> $BOARD_INFO_FILE
fi

#获取board_id
#调用脚本挂载app分区
${BOARD_ENTRY_SHELL_PATH}/${MOUNT_APP_PARTION_SHELL} $1

#判断BOARD_ID_SOURCE来源
if [ $BOARD_ID_SOURCE -eq $BOARD_ID_SOURCE_BOARD ]; then
	#预先调用ETC_ENTRY_SHELL_VENDOR_PROC_SYS脚本 app可做些预备工作
	if [ -x ${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS ]; then
		echo -n "" > $SHELL_COMM_FILE

		${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS prepare 
		${ETC_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS configuration $SHELL_COMM_FILE
		#判断返回值 是否支持读取配置
		if [ $? -eq 0 ]; then
			#支持配置读取 解析配置 在此函数中 要对board_id赋值
			configuration_parse "board_id" $SHELL_COMM_FILE
			#判断是否成功解析出board_id信息   此步也用于标识从fpga读取到的信息是否合法
			if [ $? -eq 0 ]; then
				#对BOARD_ID的值进行转换 符合boardinfo.define文件中的定义
				if [ $BOARD_ID = $BOARD_ID_NONE_VALUE ]; then
					BOARD_ID=$BOARD_ID_NONE_TEXT
				fi
				#信息合法  系统寄存器存在
				SYS_REGS_EXIST=1
			fi
		else
			#不支持配置读取  board_id为空值
			BOARD_ID=$BOARD_ID_NONE_TEXT
		fi
		#rm -rf $SHELL_COMM_FILE	
	fi
else
	#从系统命令行中获取
	proc_cmdline_value $BOARD_ID_KEY 
	if [ $? -ne 0 ]; then
		echo "BOARD_ID_SOURCE = BOARD_ID_SOURCE_CMDLINE; but $BOARD_ID_KEY do not exsit in $SYS_CMDLINE_FILE or the value is none!"
		exit 3
	fi

	BOARD_ID=$PROC_LINE_VALUE
fi

#get force value line
proc_line $BOARD_ID_FORCE_VALUE_KEY $BOARD_INFO_SRC_FILE
BOARD_ID_FORCE_VALUE=$PROC_LINE_VALUE

#force value exist
#若board id强制值存在 则使用强制值
if [ ! -z $BOARD_ID_FORCE_VALUE ]; then
	BOARD_ID=`echo ${BOARD_ID_FORCE_VALUE}|sed -e 's/ //g'`
	#对BOARD_ID的值进行转换 符合boardinfo.define文件中的定义
	if [ $BOARD_ID = $BOARD_ID_NONE_VALUE ]; then
		BOARD_ID=$BOARD_ID_NONE_TEXT
	fi
fi

#获取cpu_id
#get force value line
proc_line $CPU_ID_FORCE_VALUE_KEY $BOARD_INFO_SRC_FILE
CPU_ID_FORCE_VALUE=$PROC_LINE_VALUE

#force value exist
if [ ! -z $CPU_ID_FORCE_VALUE ]; then
	CPU_ID=`echo ${CPU_ID_FORCE_VALUE}|sed -e 's/ //g'`
else
	#判断CPU_ID_SOURCE来源
	if [ $CPU_ID_SOURCE -eq $CPU_ID_SOURCE_GPIO ]; then
		gpio_item_key="gpio_pin_list" 
		proc_line $gpio_item_key $BOARD_INFO_SRC_FILE
		CPU_ID_PIN_LIST=$PROC_LINE_VALUE
		sys_class_item_key="sys_class_gpio_file_list" 
		proc_line $sys_class_item_key $BOARD_INFO_SRC_FILE
		SYS_CLASS_GPIO_FILE_ARRAY=$PROC_LINE_VALUE

		#set array value
		ARRAY_INDEX=0
		for i in ${CPU_ID_PIN_LIST}
		do 
			CPU_ID_PIN_ARRAY[$ARRAY_INDEX]=${i}
			let "ARRAY_INDEX = $ARRAY_INDEX + 1"
		done

		#set array value
		ARRAY_INDEX=0
		for i in ${SYS_CLASS_GPIO_FILE_ARRAY}
		do 
			SYS_CLASS_GPIO_FILE_ARRAY[$ARRAY_INDEX]=${i}
			let "ARRAY_INDEX = $ARRAY_INDEX + 1"
		done

		#判断数组内元素个数是否相同
		if [ ${#CPU_ID_PIN_ARRAY[*]} -ne ${#SYS_CLASS_GPIO_FILE_ARRAY[*]} ]; then
			echo "$BOARD_INFO_SRC_FILE format error!"
			echo "$gpio_item_key list cnts != $sys_class_gpio_file_list list cnts!"
			exit 3
		fi

		#初始化关联数组
		ARRAY_INDEX=0
		for i in ${CPU_ID_PIN_ARRAY[*]}
		do
			PIN_DIR_MAP[${i}]=${SYS_CLASS_GPIO_FILE_ARRAY[${ARRAY_INDEX}]}
			let "ARRAY_INDEX = $ARRAY_INDEX + 1"
		done
		#just for test
		#输出关联数组长度  可以正常输出
		#echo ${#PIN_DIR_MAP[*]}
		#输出关联数组中所有键  不能正常输出  因为此原因 脚本中采用了两个数组来生成关联数组
		#因为下面的程序需要使用关联数组的键值
		#echo ${!PIN_DIR_MAP[@]}
		#输出关联数组中所有值  可以正常输出
		#echo ${PIN_DIR_MAP[*]}
		#输出关联数组键值为3所对应的值  可以正常输出
		#echo ${PIN_DIR_MAP[3]}

		#create gpio sysfs dir
		for i in ${CPU_ID_PIN_ARRAY[*]}
		do
			if [ ! -e $GPIO_CLASS_PATH/${PIN_DIR_MAP[${i}]}/value ]; then
				echo ${i} > $GPIO_CLASS_PATH/export
				echo "in" > $GPIO_CLASS_PATH/${PIN_DIR_MAP[${i}]}/direction
			fi
		done

		#read cpu id value
		let "ARRAY_INDEX=${#CPU_ID_PIN_ARRAY[*]} - 1"
		for i in ${CPU_ID_PIN_ARRAY[*]}
		do
			if [ ! -e $GPIO_CLASS_PATH/${PIN_DIR_MAP[${i}]}/value ]; then
				echo "$GPIO_CLASS_PATH/${PIN_DIR_MAP[${i}]}/value file do not exist! please check the software!"
			else
				CPU_ID_ARRAY[${ARRAY_INDEX}]=`cat $GPIO_CLASS_PATH/${PIN_DIR_MAP[${i}]}/value`
			fi
			let "ARRAY_INDEX = $ARRAY_INDEX - 1"
		done

		#strip space in cpu_id_array
		CPU_ID_STR=`echo ${CPU_ID_ARRAY[*]}|sed -e 's/ //g'`
		#将二进制转换为十进制
		((CPU_ID=2#$CPU_ID_STR))
	else
		#从系统命令行中获取
		proc_cmdline_value $CPU_ID_KEY 
		if [ $? -ne 0 ]; then
			echo "CPU_ID_SOURCE = CPU_ID_SOURCE_CMDLINE; but $CPU_ID_KEY do not exsit in $SYS_CMDLINE_FILE or the value is none!"
			exit 3
		fi

		CPU_ID=$PROC_LINE_VALUE
	fi
fi

debug echo "board_id = $BOARD_ID"
debug echo "cpu_id = $CPU_ID"

RT=0
BOARD_OR_CPU_ID_CHANGE=0
BOARD_ID_ORIGINAL=$BOARD_ID
CPU_ID_ORIGINAL=$CPU_ID

echo -n "" > $SHELL_ERROR_SYS_FILE

while true
do
	#调用cpu_identify_proc处理
	cpu_identify_proc $BOARD_ID $CPU_ID
	RT=$?
	if [ $RT -eq 0 ]; then
		break
	fi
	#仅仅处理board_id cpu_id的值与映射表中不匹配的情况
	if [ $RT -eq 1 ]; then
		if [ $BOARD_ID = $BOARD_ID_NONE_TEXT -a $CPU_ID = $CPU_ID_NONE_TEXT ]; then
			#此时代表映射表中没有board_id=none  cpu_id=none这一行 出错
			break
		else
			BOARD_OR_CPU_ID_CHANGE=1
			if [ ! $BOARD_ID = $BOARD_ID_NONE_TEXT ]; then
				BOARD_ID=$BOARD_ID_NONE_TEXT
				echo "assign board id = $BOARD_ID and try again"
				echo "board_id_original_value=$BOARD_ID_ORIGINAL;board_id_assign_value=$BOARD_ID" >> $SHELL_ERROR_SYS_FILE
				continue
			fi
			if [ ! $CPU_ID = $CPU_ID_NONE_TEXT ]; then
				CPU_ID=$CPU_ID_NONE_TEXT
				echo "assign cpu id = $CPU_ID and try again"
				echo "cpu_id_original_value=$CPU_ID_ORIGINAL;cpu_id_assign_value=$CPU_ID" >> $SHELL_ERROR_SYS_FILE
				continue
			fi
		fi
	else
		break
	fi
done

if [ $BOARD_OR_CPU_ID_CHANGE -ne 0 ]; then
	echo "${ERROR_KEY}={" >> $BOARD_INFO_FILE
	while read line
	do
		debug echo $line
		echo "    $line" >> $BOARD_INFO_FILE
	done  < $SHELL_ERROR_SYS_FILE
	echo "}" >> $BOARD_INFO_FILE
fi

echo "" >> $BOARD_INFO_FILE

if [ $RT -ne 0 ]; then
	echo "***************cpu identify failed! please check the configuration!***************"
fi
		
exit 0

