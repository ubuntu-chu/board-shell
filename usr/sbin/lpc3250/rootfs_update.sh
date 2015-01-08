#!/bin/sh

help(){
	echo "Usage                 : $0 <server_ip> [package_file]"
	echo "Param server_ip       : tftp server_ip"
	echo "Param package_file    : package file to application(optional, default package_file name:$DEF_PACKAGE_FILE)"
	exit 1
}

killapp(){
	vendor-sys-proc stop

	sleep 2
}

removepackage()
{
	if [ $DEL_PACKAGE_FILE -eq 1 ]; then
		echo "rm -rf $PACKAGE_FILE"
		rm -rf $PACKAGE_FILE
	fi
}

DEF_PACKAGE_FILE=itl-lpc3250-rootfs-update.tar.gz
PACKAGE_FILE=$DEF_PACKAGE_FILE
DEL_PACKAGE_FILE=1
tar_opt="zxvf"
have_valid_boarddefine=0
have_boarddefine_utility_file=0

boarddefine_get_file="/usr/sbin/boarddefine_get.sh"
boarddefine_get_file_exist=0
if [ ! -e $boarddefine_get_file ]; then
	echo "$boarddefine_get_file do not exist!"
	echo "try to use /etc/board/"
	boarddefine_utility_shell="boarddefine-utility.sh"
	boarddefine_utility_shell_full_path="/etc/board/$boarddefine_utility_shell"
	boarddefine_change_shell="boarddefine-change.sh"
	boarddefine_change_shell_full_path="/etc/board/$boarddefine_change_shell"
else
	. $boarddefine_get_file
	boarddefine_get_file_exist=1
fi

if [ $# -lt 1 -o $# -gt 2 ]; then
	help
fi

if [ $# -eq 2 ]; then
	PACKAGE_FILE=$2
fi

cd $FLASH_DIR
echo "now we are in dir:$FLASH_DIR"
echo "package file     :$PACKAGE_FILE"

TFTP_SERVER_IP=$1

if [ ! -r $PACKAGE_FILE ]; then
	echo "package_file<$PACKAGE_FILE> can not find in $FLASH_DIR! use tftp to get it!"
	echo "tftp -g -r $PACKAGE_FILE $TFTP_SERVER_IP"
	tftp -g -r $PACKAGE_FILE $TFTP_SERVER_IP
	if [ $? -ne 0 ]; then
		echo "tftp download file<$PACKAGE_FILE> from server<$TFTP_SERVER_IP> error!"
		rm -rf $PACKAGE_FILE
		exit 2
	fi
fi

which file > /dev/null
if [ $? -eq 0 ]; then

ftype=`file "$PACKAGE_FILE"`

#目前暂不支持bz压缩格式
case "$ftype" in
	*"gzip compressed"*)
		tar_opt="zxvf"
		;;

	#*"bzip2 compressed"*)
		#tar_opt="jxvf"
		#;;

	*) 
		echo "$ftype:invalid compressed format! please check!"
		removepackage
		exit 3
		;;
esac
fi

killapp

if [ $boarddefine_get_file_exist -eq 1 ]; then
	boarddefine_utility_shell_full_path_get
fi
if [ -z $boarddefine_utility_shell_full_path ]; then
	have_boarddefine_utility_file=0
else
	if [ $boarddefine_get_file_exist -eq 1 ]; then
		boarddefine_change_shell_full_path_get
	fi
	if [ -z $boarddefine_change_shell_full_path ]; then
		have_boarddefine_utility_file=2
	else
		echo "boarddefine_utility_shell_full_path=$boarddefine_utility_shell_full_path"
		echo "boarddefine_change_shell_full_path=$boarddefine_change_shell_full_path"
		. $boarddefine_utility_shell_full_path

		#获取当前板载定义配置
		generate_var_from_file "${PREV_DEFINE_KEY}" "$BOARD_INFO_SRC_FILE"

		have_boarddefine_utility_file=1
		if [ ${#key_array[*]} -eq 0 ]; then
			have_valid_boarddefine=0
		else
			have_valid_boarddefine=1
		fi
	fi
fi

echo "rm -rf /etc/board"
rm -rf /etc/board
echo "tar $tar_opt $PACKAGE_FILE -C /"
tar $tar_opt $PACKAGE_FILE -C /

if [ $? -eq 0 ]; then
	echo "run /etc/board/customize.sh"
	/etc/board/customize.sh
	echo "you can run /etc/board/validate-boardinfo.sh to view new boardinfo"
	removepackage
	echo "rootfs update success!"
	if [ $have_valid_boarddefine -eq 1 ]; then
		echo "recover previous board define info"
		config_array=()
		index=0
		while :;
		do
			#不传入board_type参数
			if [ ! ${key_array[$index]} = "board_type" ]; then
				config_array[$index]="--${key_array[$index]} ${value_array[$index]}"
			fi
			index=$(($index + 1))
			if [ $index -ge ${#key_array[*]} ]; then
				break
			fi
		done
		echo "$boarddefine_change_shell_full_path ${config_array[*]}"
		$boarddefine_change_shell_full_path ${config_array[*]}
	else
		if [ $have_boarddefine_utility_file -eq 0 ]; then
			echo "$boarddefine_utility_shell  do not exist!"
			echo "you must manual set baord define info by run $boarddefine_change_shell_full_path!"
		else
			if [ $have_boarddefine_utility_file -eq 1 ]; then
				echo "$BOARD_INFO_SRC_FILE file do not have a valid board define! you must manual set baord define info by run $boarddefine_change_shell_full_path!"
			else
				echo "$boarddefine_change_shell_full_path do not exist!"
				echo "please check what happend!"
			fi
		fi
	fi
else
	echo "rootfs update failed!"
fi



