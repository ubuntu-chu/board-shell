#!/bin/bash

boarddefine_change_exec_shell="exec-boarddefine-change.sh"
opt_itl_sbin_path="/opt/itl/sbin"
boarddefine_change_exec_shell_opt_itl_sbin=$opt_itl_sbin_path/$boarddefine_change_exec_shell
etc_board_path="/etc/board"
boarddefine_change_exec_shell_etc_board=$etc_board_path/$boarddefine_change_exec_shell
rcs_board="rcS.board"

#优先级固定 先查找/opt/itl/sbin目录  再查找/etc/board目录
if [ -e $boarddefine_change_exec_shell_opt_itl_sbin ]; then
	if [ ! -x $boarddefine_change_exec_shell_opt_itl_sbin ]; then
		chmod a+x $boarddefine_change_exec_shell_opt_itl_sbin
	fi
	boarddefine_change_exec_shell_path=$boarddefine_change_exec_shell_opt_itl_sbin
	rcs_board_path=$opt_itl_sbin_path/$rcs_board
else
	if [ -e $boarddefine_change_exec_shell_etc_board ]; then
		if [ ! -x $boarddefine_change_exec_shell_etc_board ]; then
			chmod a+x $boarddefine_change_exec_shell_etc_board
		fi
		boarddefine_change_exec_shell_path=$boarddefine_change_exec_shell_etc_board
		rcs_board_path=$etc_board_path/$rcs_board
	else
		echo "$boarddefine_change_exec_shell can not find! please check what happened!"	
		exit 1
	fi
fi

echo "$boarddefine_change_exec_shell_path"
. $boarddefine_change_exec_shell_path $@



