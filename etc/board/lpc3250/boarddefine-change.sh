#!/bin/bash

boarddefine_change_exec_shell="exec-boarddefine-change.sh"
boarddefine_change_exec_shell_path='which $boarddefine_change_exec_shell'

if [ $? -eq 0 ]; then
	echo "$boarddefine_change_exec_shell_path"
	. $boarddefine_change_exec_shell_path $@
fi



