#!/bin/sh


rootfs_common_path="/home/chum/work/lte/rootfs-common"

cpu_name_lpc3250=lpc3250
cpu_name_tci6614=tci6614


#拷贝打包脚本到相应的目录中
cp $rootfs_common_path/pack-shell/$cpu_name_lpc3250/*  /home/chum/work/lte/lpc3250
cp $rootfs_common_path/pack-shell/$cpu_name_tci6614/*  /home/chum/work/lte/


