#!/bin/bash

. /etc/board/rcS

#暂时文件
temp_file="/var/tmp/temp_file"

#键数组
key_array=()
#值数组
value_array=()

file_lines_proc()
{
	#去除首部 尾部的空格  以及=号前后的空格
	#将空格替换为_
	sed -i "s/^[[:space:]]*//;s/ *= */=/;s/[[:space:]]*$//;s/[[:space:]]/_/g" $1
}

generate_var_from_file()
{
	#键数组
	key_array=()
	#值数组
	value_array=()

	echo -n "" > $temp_file
	sed -n "/^""${1}""={/,/^}/ p"  $2 \
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

	rm -rf $temp_file

	#debug echo ${key_array[*]}
	#debug echo ${value_array[*]}
}


