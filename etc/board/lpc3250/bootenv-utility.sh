#!/bin/sh
#
# 修改boot环境变量
# 
#

. /etc/board/rcS
. /usr/sbin/partion_utility.sh

ubootenv_partion_name="norflash:uboot-env"
dump_name="/var/run/uboot-env.bin"

ubootenv_dump()
{
	partion_find $ubootenv_partion_name

	if [ $? -ne 0 ]; then
		echo "$0:partion find failed!"
		return 1
	fi

	debug echo "dd if=$PARTION_DEV_FILE of=$dump_name"
	dd if=$PARTION_DEV_FILE of=$dump_name
	if [ $? -ne 0 ]; then
		echo "$0:dd execute failed!"
		return 2
	fi

	return 0
}

ubootenv_recover()
{
	partion_find $ubootenv_partion_name

	if [ $? -ne 0 ]; then
		echo "$0:partion find failed!"
		return 1
	fi

	debug echo "dd if=$dump_name of=$PARTION_DEV_FILE"
	dd if=$dump_name of=$PARTION_DEV_FILE
	if [ $? -ne 0 ]; then
		echo "$0:dd execute failed!"
		return 2
	fi

	return 0
}

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

	fw_printenv > $uboot_env_original_file 2>&1

	egrep "Warning:.*Bad.*CRC" $uboot_env_original_file > /dev/null
	if [ $? -eq 0 ]; then
		echo "bootenv crc check failed! so discard changes and exit"
		return 2	
	fi
	#因为uboot版本可能老旧的原因  org_value 可以不存在
	#uboot_env_original_file中如果出现crc错误 则直接退出 不能再继续执行修改
	proc_line_return ${1} ${uboot_env_original_file}
	if [ $? -eq 0 ]; then
		org_value=$PROC_LINE_VALUE
	fi

	debug echo "key = $key"
	debug echo "new_value = $new_value"
	debug echo "org_value = $org_value"

	#加入x的原因在于  防止变量为空
	if [ ! "$new_value"x = "$org_value"x ]; then
		echo "dump boot env to $dump_name"
		ubootenv_dump
		if [ $? -ne 0 ]; then
			echo "dump boot env failed!"
			return 1
		fi

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

	echo -n "bootenv change [key = $key, old_value = $org_value, new_value = $new_value]"
	#值不相等 或 新值为空
	if [ ! "$new_value"x = "$chk_value"x ]; then
		echo " failed"
		echo "recover $dump_name to boot env"
		ubootenv_recover
		if [ $? -ne 0 ]; then
			echo "dump boot env failed!"
		fi
		#更改失败
		return 1
	fi
	echo " success"

	return 0
}


