#!/bin/bash

boarddefine_utility_shell="boarddefine-utility.sh"
boarddefine_utility_shell_opt_itl_sbin="/opt/itl/sbin/$boarddefine_utility_shell"
boarddefine_utility_shell_etc_board="/etc/board/$boarddefine_utility_shell"
boarddefine_utility_shell_full_path=

boarddefine_utility_shell_full_path_get()
{
	#此处为兼容处理
	#/opt/itl/sbin 下脚本优先  
	#弄两个脚本的目的在于 提供多一种选择 防止app分区损坏等
	if [ -e $boarddefine_utility_shell_opt_itl_sbin ]; then
		if [ ! -x $boarddefine_utility_shell_opt_itl_sbin ]; then
			chmod a+x $boarddefine_utility_shell_opt_itl_sbin
		fi
		boarddefine_utility_file_full_path=$boarddefine_utility_shell_opt_itl_sbin
	else 
		if [ -e $boarddefine_utility_shell_etc_board ]; then
			if [ ! -x $boarddefine_utility_shell_etc_board ]; then
				chmod a+x $boarddefine_utility_shell_etc_board
			fi
			boarddefine_utility_file_full_path=$boarddefine_utility_shell_etc_board
		else
			echo "$boarddefine_utility_shell  do not exist!"
			return 1
		fi
	fi

	return 0
}


boarddefine_change_shell="boarddefine-change.sh"
boarddefine_change_shell_opt_itl_sbin="/opt/itl/sbin/$boarddefine_change_shell"
boarddefine_change_shell_etc_board="/etc/board/$boarddefine_change_shell"
boarddefine_change_shell_full_path=

boarddefine_change_shell_full_path_get()
{
	#此处为兼容处理
	#/opt/itl/sbin 下脚本优先  
	#弄两个脚本的目的在于 提供多一种选择 防止app分区损坏等
	if [ -x $boarddefine_change_shell_opt_itl_sbin ]; then
		if [ ! -x $boarddefine_change_shell_opt_itl_sbin ]; then
			chmod a+x $boarddefine_change_shell_opt_itl_sbin
		fi
		boarddefine_change_file_full_path=$boarddefine_change_shell_opt_itl_sbin
	else 
		if [ -x $boarddefine_change_shell_etc_board ]; then
			if [ ! -x $boarddefine_change_shell_etc_board ]; then
				chmod a+x $boarddefine_change_shell_etc_board
			fi
			boarddefine_change_file_full_path=$boarddefine_change_shell_etc_board
		else
			echo "$boarddefine_change_shell  do not exist!"
			return 1
		fi
	fi

	return 0
}


