#!/bin/sh
#
# 修改boot环境变量
# 
#

. /etc/board/rcS

#参数：  $1：要修改的环境变量
#        $2：环境变量的新值
ubootenv_modify()
{
	key=$1
	org_value=
	new_value=$2
	chk_value=
	uboot_env_check_file="/var/run/ubootenv_check_file"
	uboot_env_original_file="/var/run/ubootenv_original_file"

	fw_printenv > $uboot_env_original_file

	#因为uboot版本可能老旧的原因  org_value 可以不存在
	proc_line_return ${1} ${uboot_env_original_file}
	if [ $? -eq 0 ]; then
		org_value=$PROC_LINE_VALUE
	fi

	debug echo "key = $key"
	debug echo "new_value = $new_value"
	debug echo "org_value = $org_value"

	#加入x的原因在于  防止变量为空
	if [ ! "$new_value"x = "$org_value"x ]; then
		#执行更改
		fw_setenv ${key} ${new_value} > /dev/null 2>&1
	else
		#值相等  直接返回
		return 0
	fi

	#检验是否更改正确
	fw_printenv > $uboot_env_check_file
	proc_line_return ${key} ${uboot_env_check_file}
	if [ $? -eq 0 ]; then
		chk_value=$PROC_LINE_VALUE
	fi

	#值不相等 或 新值为空
	if [ ! "$new_value"x = "$chk_value"x ]; then
		#更改失败
		return 1
	fi

	return 0
}


