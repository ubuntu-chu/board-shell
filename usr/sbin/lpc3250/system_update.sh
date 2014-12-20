#!/bin/sh

TFTP_SERVER_IP=192.192.192.201
CCU_KEY="ccu"
RRU_KEY="rru"
APP_PACKAGE=
STEP_1=1
STEP_2=2
STEP_3=3
STEP_4=4

help(){
	echo "Usage                 : $0 <board_class> <step>"
	echo "Param board_class     : <$CCU_KEY|$RRU_KEY>"
	echo "Param step            : <$STEP_1|$STEP_2|$STEP_3|$STEP_4> $STEP_2-$STEP_3 for rootfs, $STEP_4 only for recover-rootfs"
	exit 1
}

execute_cmd()
{
	echo "$@"
	$@
	if [ $? -ne 0 ];then
		echo "execute $@ failed! please check what happened!"
		exit 1
	fi
}

if [ $# -ne 2 ]; then
	help
fi

case $1 in
	$CCU_KEY)
		APP_PACKAGE=itl-lpc3250-app-ccu.tar.gz
		;;
	$RRU_KEY)
		APP_PACKAGE=itl-lpc3250-app-rru.tar.gz
		;;
	*)
		help
		;;
esac

case $2 in
	$STEP_1)

		#第一步
		#将rootfs_update.sh脚本通过winscp工具上传到根文件系统中的  /usr/sbin目录下  并添加执行权限 chmod a+x rootfs_update.sh
		#升级根文件系统
		execute_cmd rootfs_update.sh $TFTP_SERVER_IP itl-lpc3250-rootfs-update.tar.gz
		#升级应用程序包
		execute_cmd app_install_upgrade.sh $TFTP_SERVER_IP $APP_PACKAGE
		#升级内核
		execute_cmd kernel_partion_flash.sh $TFTP_SERVER_IP itl-lpc3250-uImage
		#重烧写恢复所用根文件系统  原因在于恢复所用根文件系统所有使用的uboot变量在新的uboot变量中可能已经不存在了 所以导致恢复所用根文件系统无法启动
		execute_cmd recover_rootfs_partion_flash.sh $TFTP_SERVER_IP itl-lpc3250-rootfs-recover.img
		#重启，此时使用的环境变量仍然为uboot中存在的老旧的环境变量
		reboot
		;;
	$STEP_2)

		#第二步
		#升级bootloader
		execute_cmd bootloader_partion_flash.sh $TFTP_SERVER_IP itl-lpc3250-bootloader-3in1.bin
		#重启 使用新的boot环境变量，并自动保存环境变量
		reboot
		;;

	$STEP_3)

		#第三步
		#重启进入到恢复模式
		execute_cmd recovery_mode_restart.sh
		;;
	$STEP_4)

		#第四步
		#恢复根文件系统中
		#升级根文件系统
		execute_cmd rootfs_partion_flash.sh $TFTP_SERVER_IP itl-lpc3250-rootfs.img
		#重启进入到正常模式 此时使用根文件系统
		execute_cmd normal_mode_restart.sh
		;;
	*)
		help
		;;
esac





