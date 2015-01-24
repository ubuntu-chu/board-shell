#!/bin/sh

#此脚本废弃 
echo "$SUDO_PASSWD" | sudo -S cp etc/board/lpc3250/car_central_station/rru/rcS.board /etc/board/
echo "$SUDO_PASSWD" | sudo -S cp etc/board/exec-boarddefine-change.sh /etc/board/


#rootfs_common_path="/home/chum/work/lte/board-shell"
#
#cpu_name_lpc3250=lpc3250
#cpu_name_tci6614=tci6614
#
#
##拷贝打包脚本到相应的目录中
#cp $rootfs_common_path/pack-shell/$cpu_name_lpc3250/*  /home/chum/work/lte/lpc3250
#cp $rootfs_common_path/pack-shell/$cpu_name_tci6614/*  /home/chum/work/lte/
#

