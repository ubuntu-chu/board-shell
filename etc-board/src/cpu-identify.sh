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
	value=`awk '{if ($1 == "'"${1}"'" && $2 == '${2}'){print $0}}' $BOARD_INFO_SRC_FILE`
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
		return 1
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
		return 2
	fi

	echo "************board info definition************" > $BOARD_INFO_FILE
	echo "" >> $BOARD_INFO_FILE

	echo "basic={" >> $BOARD_INFO_FILE
	index=0
	while true
	do
		#将除proc之外的列写入到$BOARD_INFO_FILE
		if [ ${item_array[$index]} != ${PROC_KEY} -a  ${item_array[$index]} != ${NETWORK_KEY} ]; then
			#将数组中的内容写入到文件中
			echo "    ${item_array[$index]}=${value_array[$index]}" >> $BOARD_INFO_FILE
		else 
			if [ ${item_array[$index]} = ${NETWORK_KEY} ]; then
				#记录network列的索引
				network_index=$index
			else
				#记录proc列的索引
				proc_index=$index
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
	if [ ${1} = "none" ]; then
		mac_board_id=ff
	else
		mac_board_id=`printf "%02x" ${1}`
	fi
	#获取mac_cpu_id
	if [ ${2} = "none" ]; then
		mac_cpu_id=0f
	else
		mac_cpu_id=`printf "%02x" ${2}`
	fi
	#获取匹配的行号
	replace_nu_list=`egrep "${MAC_HWADDRESS_KEY} +${MAC_VALUE_KEY}*" -n ${BOARD_INFO_FILE}|cut -d ':' -f 0`
	debug echo "replace_nu_list = $replace_nu_list"
	mac_nic=0
	for i in $replace_nu_list;
	do 
		mac_lowest=$(($mac_nic+$mac_cpu_id))
		#let "mac_cpu_id=$mac_cpu_id_high+$mac_cpu_id_low"
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

	#当board_id不为none时  代表系统寄存器存在
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
		proc_content=`awk '/^'${proc_value}'=\{/,/^\}/ {print $0}' "${BOARD_INFO_SRC_FILE}"\
			| sed '1d;s/^[[:space:]]*//' | sed '1,$ s/^/    /;s/= \+\(\w\)/=\1/' | sed '$ s/^[[:space:]]*//' \
			| awk '{print $0}' | tee -a ${BOARD_INFO_FILE}`

		debug echo "before proc_content=$proc_content"
		proc_content=`echo $proc_content|tr -d "{}"| tr -s " "| tr " " ":"|sed 's/:$//'`
		debug echo "after proc_content=$proc_content"
		#判断内核当前是否已经加载了此内核模块 若已加载 则先卸载
		#删除可能存在的双引号
		PROC_MODULE=`echo $PROC_MODULE|tr -d \"`
		lsmod|grep "${PROC_MODULE}" > /dev/null
		if [ $? -eq 0 ]; then
			rmmod $BOARD_ENTRY_SHELL_PATH/${PROC_MODULE}
		fi
		insmod $BOARD_ENTRY_SHELL_PATH/${PROC_MODULE}.ko proc_dir=${COMPANY} files_list=${proc_content}
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

	echo "}" >> $BOARD_INFO_FILE
	
	#get item line
	build_time=`grep -E "^\<${BUILD_TIME_KEY}\>" $BOARD_INFO_SRC_FILE`
	if [ ! -z "$build_time" ]; then
		echo $build_time >> $BOARD_INFO_FILE
	fi
	
	echo "" >> $BOARD_INFO_FILE

	return 0
}

if [ ! "$1" = "start" ]; then
	exit 0
fi

echo "Starting cpu identify..." 

#获取board_id
#调用脚本挂载app分区
${BOARD_ENTRY_SHELL_PATH}/${MOUNT_APP_PARTION_SHELL} $1

#get force value line
proc_line $BOARD_ID_FORCE_VALUE_KEY $BOARD_INFO_SRC_FILE
BOARD_ID_FORCE_VALUE=$PROC_LINE_VALUE

#force value exist
if [ ! -z $BOARD_ID_FORCE_VALUE ]; then
	BOARD_ID=`echo ${BOARD_ID_FORCE_VALUE}|sed -e 's/ //g'`
	#对BOARD_ID的值进行转换 符合boardinfo.define文件中的定义
	if [ $BOARD_ID = $BOARD_ID_NONE_VALUE ]; then
		BOARD_ID=$BOARD_ID_NONE_TEXT
	fi
else
	#判断BOARD_ID_SOURCE来源
	if [ $BOARD_ID_SOURCE -eq $BOARD_ID_SOURCE_BOARD ]; then
		#预先调用ETC_ENTRY_SHELL_VENDOR_PROC_SYS脚本 app可做些预备工作
		if [ -x ${ETC_APP_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS ]; then
			echo -n "" > $SHELL_COMM_FILE

			${ETC_APP_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS prepare 
			${ETC_APP_ENTRY_SHELL_PATH}/$ETC_ENTRY_SHELL_VENDOR_PROC_SYS configuration $SHELL_COMM_FILE
			#判断返回值 是否支持读取配置
			if [ $? -eq 0 ]; then
				#支持配置读取 解析配置 在此函数中 要对board_id赋值
				configuration_parse "board_id" $SHELL_COMM_FILE
				#对BOARD_ID的值进行转换 符合boardinfo.define文件中的定义
				if [ $BOARD_ID = $BOARD_ID_NONE_VALUE ]; then
					BOARD_ID=$BOARD_ID_NONE_TEXT
				fi
				SYS_REGS_EXIST=1
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
			exit 3
		fi

		BOARD_ID=$PROC_LINE_VALUE
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
			exit 3
		fi

		CPU_ID=$PROC_LINE_VALUE
	fi
fi

debug echo "board_id = $BOARD_ID"
debug echo "cpu_id = $CPU_ID"

#调用cpu_identify_proc处理
cpu_identify_proc $BOARD_ID $CPU_ID

if [ $? -ne 0 ]; then
	echo "***************cpu identify failed! please check the configuration!***************"
fi
		
exit 0

