#!/bin/sh

LPC3250_KEY="lpc3250"
LPC3250_MISC_KEY="lpc3250_misc"
TCI6614_KEY="tci6614"
ALL_KEY="all"
UPDATE_KEY="update"
LPC3250_UPDATE_KEY="update_lpc3250"
TCI6614_UPDATE_KEY="update_tci6614"
PACK_SHELL="pack-shell"

CAR_CENTRAL_STATION="car_central_station"
RELAY_STATION="relay_station"
METROCELL="metrocell"

version_file=etc/board/auto_generate_version
now_path=`pwd`

ETC_BOARD_SUFFIX="etc/board"
ETC_RCD_SUFFIX="etc/rc.d"
ETC_INITD_SUFFIX="etc/init.d"
USR_SBIN_SUFFIX="usr/sbin"
USR_SHARE_SUFFIX="usr/share"
BIN_SUFFIX="bin"
SBIN_SUFFIX="sbin"
PRIVATE_SUFFIX="private"

rootfs_common_path="/home/chum/work/lte/board-shell"
ETC_BOARD_SRC_PATH="$rootfs_common_path/$ETC_BOARD_SUFFIX/"
ETC_RCD_SRC_PATH="$rootfs_common_path/$ETC_RCD_SUFFIX/"
ETC_BOARD_PRIVATE_SRC_PATH="$rootfs_common_path/$ETC_BOARD_SUFFIX/$PRIVATE_SUFFIX"
USR_SBIN_SRC_PATH="$rootfs_common_path/$USR_SBIN_SUFFIX/"
USR_SHARE_SRC_PATH="$rootfs_common_path/$USR_SHARE_SUFFIX/"
BIN_SRC_PATH="$rootfs_common_path/$BIN_SUFFIX/"
SBIN_SRC_PATH="$rootfs_common_path/$SBIN_SUFFIX/"

rootfs_update_path="$rootfs_common_path/rootfs_update_lpc3250"
rootfs_update_path_etc_board="$rootfs_update_path/$ETC_BOARD_SUFFIX"
rootfs_update_path_etc_board_private="$rootfs_update_path/$ETC_BOARD_SUFFIX/$PRIVATE_SUFFIX"
rootfs_update_path_usr_sbin="$rootfs_update_path/$USR_SBIN_SUFFIX"
rootfs_update_path_usr_share="$rootfs_update_path/$USR_SHARE_SUFFIX"
rootfs_update_path_bin="$rootfs_update_path/$BIN_SUFFIX"
rootfs_update_path_sbin="$rootfs_update_path/$SBIN_SUFFIX"
rootfs_update_tar_name="itl-lpc3250-rootfs-update.tar.gz"

cpu_name_lpc3250=lpc3250
cpu_name_tci6614=tci6614

tci6614_path_set()
{
	TCI6614_DEST_PATH="/home/chum/work/lte/install_package/rootfs/tci6614/$station"
	#TCI6614_DEST_PATH="/home/chum/work/lte"
	#用于测试
	#TCI6614_ROOTFS_DEST_PATH="/home/chum/test/tci6614"
	TCI6614_ROOTFS_DEST_PATH="$TCI6614_DEST_PATH/rootfs"
	TCI6614_ETC_BOARD_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$ETC_BOARD_SUFFIX"
	TCI6614_ETC_BOARD_PRIVATE_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$ETC_BOARD_SUFFIX/$PRIVATE_SUFFIX"
	TCI6614_USR_SBIN_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$USR_SBIN_SUFFIX"
	TCI6614_USR_SHARE_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$USR_SHARE_SUFFIX"
	TCI6614_BIN_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$BIN_SUFFIX"
	TCI6614_SBIN_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$SBIN_SUFFIX"
}

lpc3250_path_set()
{
	LPC3250_DEST_PATH="/home/chum/work/lte/install_package/rootfs/lpc3250/$station"
	#LPC3250_DEST_PATH="/home/chum/work/lte/lpc3250"
	#用于测试
	#LPC3250_ROOTFS_DEST_PATH="/home/chum/test/lpc3250"
	LPC3250_ROOTFS_DEST_PATH="$LPC3250_DEST_PATH/rootfs"
	LPC3250_ETC_BOARD_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$ETC_BOARD_SUFFIX"
	LPC3250_ETC_BOARD_PRIVATE_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$ETC_BOARD_SUFFIX/$PRIVATE_SUFFIX"
	LPC3250_USR_SBIN_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$USR_SBIN_SUFFIX"
	LPC3250_USR_SHARE_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$USR_SHARE_SUFFIX"
	LPC3250_BIN_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$BIN_SUFFIX"
	LPC3250_SBIN_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$SBIN_SUFFIX"
}

station_get()
{
	case "$1" in
		$CAR_CENTRAL_STATION)
		#$CAR_CENTRAL_STATION|$RELAY_STATION|$METROCELL)
			station=$1
			echo "station = $station"
			lpc3250_path_set
			tci6614_path_set
			;;
		*)
			echo "invalid station[$1]"
			exit 2
			;;
	esac
}

install_files()
{
	files_list_1=`find $1 -maxdepth 1 -type f`
	files_list_2=`find $1 -maxdepth 1 -type l`
	files_list_3=`find $1/$2 -maxdepth 1 -type f`
	files_list_4=`find $1/$2 -maxdepth 1 -type l`

	for i in $files_list_1 $files_list_2 $files_list_3 $files_list_4;
	do
	       #echo "cp $i $3/"
		   cp -a $i $3/
		   #echo -n ""
	done

	#now_path=`pwd`
	#cd $1/$2
	##拷贝目录
	#dir_list=`find . -type d`
	##echo "dir-list: $dir_list"
	#for i in $dir_list;
	#do
	#	i=`basename $i`
	#	#忽略当前目录
	#	if [ $i = "." ]; then
	#		continue
	#	fi
	#	[ -d $3/$i ] || mkdir -p $3/$i
	#	echo "cp -ra $i $3/"
	#	cp -ra $i $3/
	#	echo ""
	#done
	#cd $now_path
}

install_link()
{
	files_list_1=`find $1 -maxdepth 1 -type l`
	files_list_2=`find $1/$2 -maxdepth 1 -type l`

	for i in $files_list_1 $files_list_2;
	do
	       #echo "cp $i $3/"
		   cp -a $i $3/
		   #echo -n ""
	done
}

install_usr_share()
{
	cp -ar $1/file/* $2/file
	cp -a $1/misc/* $2/misc
}

help(){
	echo "Usage                 : $0 <$LPC3250_MISC_KEY|$LPC3250_KEY|$TCI6614_KEY|$ALL_KEY|$LPC3250_UPDATE_KEY|$TCI6614_UPDATE_KEY|$UPDATE_KEY|$PACK_SHELL> <$CAR_CENTRAL_STATION|$RELAY_STATION|$METROCELL>"
	exit 1
}

#此函数要放在install_rootfs_update函数之后运行
install_rootfs_update_tci6614()
{
	rootfs_update_path="$rootfs_common_path/rootfs_update_tci6614"
	rootfs_update_path_etc_board="$rootfs_update_path/$ETC_BOARD_SUFFIX"
	rootfs_update_path_etc_board_private="$rootfs_update_path/$ETC_BOARD_SUFFIX/$PRIVATE_SUFFIX"
	rootfs_update_path_usr_sbin="$rootfs_update_path/$USR_SBIN_SUFFIX"
	rootfs_update_path_usr_share="$rootfs_update_path/$USR_SHARE_SUFFIX"
	rootfs_update_path_bin="$rootfs_update_path/$BIN_SUFFIX"
	rootfs_update_path_sbin="$rootfs_update_path/$SBIN_SUFFIX"
	rootfs_update_tar_name="itl-tci6614-rootfs-update.tar.gz"

	rm -rf $rootfs_update_path
	mkdir -p $rootfs_update_path_bin
	mkdir -p $rootfs_update_path_sbin
	mkdir -p $rootfs_update_path_etc_board
	mkdir -p $rootfs_update_path_etc_board_private
	mkdir -p $rootfs_update_path_usr_sbin
	mkdir -p $rootfs_update_path_usr_share/file
	mkdir -p $rootfs_update_path_usr_share/misc
	mkdir -p $rootfs_update_path_usr_share/file/maigc

	mkdir -p $rootfs_update_path/$ETC_INITD_SUFFIX

	install_files $ETC_BOARD_SRC_PATH $cpu_name_tci6614 $rootfs_update_path_etc_board
	cp -ar $ETC_BOARD_SRC_PATH/$cpu_name_tci6614/$station/*  $rootfs_update_path_etc_board


	install_files $ETC_BOARD_PRIVATE_SRC_PATH $cpu_name_tci6614 $rootfs_update_path_etc_board_private
	install_files $USR_SBIN_SRC_PATH $cpu_name_tci6614 $rootfs_update_path_usr_sbin
	install_files $BIN_SRC_PATH $cpu_name_tci6614 $rootfs_update_path_bin
	install_files $SBIN_SRC_PATH $cpu_name_tci6614 $rootfs_update_path_sbin
	install_usr_share $USR_SHARE_SRC_PATH $rootfs_update_path_usr_share

	cp -r $rootfs_common_path/etc/$cpu_name_tci6614/* $rootfs_update_path/etc/
	cp $rootfs_common_path/etc/$cpu_name_tci6614/init.d/rc $rootfs_update_path/$ETC_INITD_SUFFIX

	cd $rootfs_update_path
	tar zcf $rootfs_update_tar_name ./*
	cd ..
	mv $rootfs_update_path/$rootfs_update_tar_name .

	if [ -z ${TFTP_SERVER_DIR}  ]; then
		echo "copy abort due to var TFTP_SERVER_DIR = null"
		exit 0
	fi

	echo "cp $rootfs_update_tar_name ${TFTP_SERVER_DIR}/"
	cp $rootfs_update_tar_name ${TFTP_SERVER_DIR}/

}

install_rootfs_update()
{
	rm -rf $rootfs_update_path
	mkdir -p $rootfs_update_path_bin
	mkdir -p $rootfs_update_path_sbin
	mkdir -p $rootfs_update_path_etc_board
	mkdir -p $rootfs_update_path_etc_board_private
	mkdir -p $rootfs_update_path_usr_sbin
	mkdir -p $rootfs_update_path_usr_share/file
	mkdir -p $rootfs_update_path_usr_share/misc
	mkdir -p $rootfs_update_path_usr_share/file/maigc

	mkdir -p $rootfs_update_path/$ETC_RCD_SUFFIX

	#set -x
	install_files $ETC_BOARD_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_etc_board
	cp -ar $ETC_BOARD_SRC_PATH/$cpu_name_lpc3250/$station/*  $rootfs_update_path_etc_board
	#set +x

	install_files $ETC_BOARD_PRIVATE_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_etc_board_private
	install_files $USR_SBIN_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_usr_sbin
	install_files $BIN_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_bin
	install_files $SBIN_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_sbin
	install_usr_share $USR_SHARE_SRC_PATH $rootfs_update_path_usr_share

	cp -r $rootfs_common_path/etc/$cpu_name_lpc3250/* $rootfs_update_path/etc/
	cp $rootfs_common_path/etc/$cpu_name_lpc3250/rc.d/rcS $rootfs_update_path/$ETC_RCD_SUFFIX

	cd $rootfs_update_path
	tar zcf $rootfs_update_tar_name ./*
	cd ..
	mv $rootfs_update_path/$rootfs_update_tar_name .

	install_lpc3250_misc

	if [ -z ${TFTP_SERVER_DIR}  ]; then
		echo "copy abort due to var TFTP_SERVER_DIR = null"
		exit 0
	fi

	echo "cp $rootfs_update_tar_name ${TFTP_SERVER_DIR}/"
	cp $rootfs_update_tar_name ${TFTP_SERVER_DIR}/
}

install_lpc3250_misc()
{
	#将脚本拷贝到本地PC中
	echo "echo "$SUDO_PASSWD" | sudo -S cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/* /etc/board/"
	echo "$SUDO_PASSWD" | sudo -S cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/* /etc/board/

	station_list=`echo "$SUDO_PASSWD" | sudo -S /etc/board/station-change.sh --info_simple`

	dest_app_package_ccu_dir=/home/chum/work/lte/install_package/app/lpc3250/car_central_station/ccu/opt/itl/sbin/
	dest_app_package_rru_dir=/home/chum/work/lte/install_package/app/lpc3250/car_central_station/rru/opt/itl/sbin/
	#将boarddefine下的脚本拷贝到app安装包中
	for dir in  $dest_app_package_ccu_dir $dest_app_package_rru_dir;
	do
		#echo "cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/exec-boarddefine-change.sh  $dir"
		#cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/exec-boarddefine-change.sh  $dir
		echo "cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/exec-boarddefine-change.sh  $dir"
		cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/exec-boarddefine-change.sh  $dir

		if [ $dir = $dest_app_package_ccu_dir ]; then

			echo "cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/$station/ccu/rcS.board  $dir"
			cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/$station/ccu/rcS.board  $dir
		else

			echo "cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/$station/rru/rcS.board  $dir"
			cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/$station/rru/rcS.board  $dir
		fi

		#for station in $station_list; 
		#do
		#	[ -d $dir/$station ] || mkdir -p $dir/$station
		#	echo "cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/$station/rcS.board  $dir/$station"
		#	cp -r $rootfs_common_path/$ETC_BOARD_SUFFIX/$cpu_name_lpc3250/$station/rcS.board  $dir/$station
		#done
		
	done
}

install_lpc3250()
{

	rm -rf $LPC3250_ETC_BOARD_DEST_PATH/*
	mkdir -p $LPC3250_ETC_BOARD_PRIVATE_DEST_PATH
	install_files $ETC_BOARD_SRC_PATH $cpu_name_lpc3250 $LPC3250_ETC_BOARD_DEST_PATH
	#忽略目录下子目录的拷贝
	echo "cp $ETC_BOARD_SRC_PATH/$cpu_name_lpc3250/$station/*  $LPC3250_ETC_BOARD_DEST_PATH"
	cp $ETC_BOARD_SRC_PATH/$cpu_name_lpc3250/$station/*  $LPC3250_ETC_BOARD_DEST_PATH

	install_files $ETC_BOARD_PRIVATE_SRC_PATH $cpu_name_lpc3250 $LPC3250_ETC_BOARD_PRIVATE_DEST_PATH
	#set -x
	install_files $USR_SBIN_SRC_PATH $cpu_name_lpc3250 $LPC3250_USR_SBIN_DEST_PATH
	#set +x
	install_files $BIN_SRC_PATH $cpu_name_lpc3250 $LPC3250_BIN_DEST_PATH
	install_files $SBIN_SRC_PATH $cpu_name_lpc3250 $LPC3250_SBIN_DEST_PATH
	install_usr_share $USR_SHARE_SRC_PATH $LPC3250_USR_SHARE_DEST_PATH

	install_lpc3250_misc
}

install_tci6614()
{

	rm -rf $TCI6614_ETC_BOARD_DEST_PATH/*
	mkdir -p $TCI6614_ETC_BOARD_PRIVATE_DEST_PATH
	install_files $ETC_BOARD_SRC_PATH $cpu_name_tci6614 $TCI6614_ETC_BOARD_DEST_PATH
	#忽略目录下子目录的拷贝
	echo "cp $ETC_BOARD_SRC_PATH/$cpu_name_tci6614/$station/*  $TCI6614_ETC_BOARD_DEST_PATH"
	cp $ETC_BOARD_SRC_PATH/$cpu_name_tci6614/$station/*  $TCI6614_ETC_BOARD_DEST_PATH

	install_files $ETC_BOARD_PRIVATE_SRC_PATH $cpu_name_tci6614 $TCI6614_ETC_BOARD_PRIVATE_DEST_PATH
	install_files $USR_SBIN_SRC_PATH $cpu_name_tci6614 $TCI6614_USR_SBIN_DEST_PATH
	#install_files $BIN_SRC_PATH $cpu_name_tci6614 $TCI6614_BIN_DEST_PATH
	#install_link $SBIN_SRC_PATH $cpu_name_tci6614 $TCI6614_SBIN_DEST_PATH
	install_usr_share $USR_SHARE_SRC_PATH $TCI6614_USR_SHARE_DEST_PATH

	cp -r $rootfs_common_path/etc/$cpu_name_tci6614/* $TCI6614_ROOTFS_DEST_PATH/etc/
	cp $rootfs_common_path/etc/$cpu_name_tci6614/init.d/rc $TCI6614_ROOTFS_DEST_PATH/$ETC_INITD_SUFFIX
}

generate_version_file()
{
	#版本前缀
	[ -z $ver_prefix   ] && ver_prefix="svn."

	echo "cd $1"
	cd $1
	version="$ver_prefix`svn info | sed -n 's,^最后修改的版本: \(.*\),\1,p'`"
	cd $now_path
	echo "echo "rootfs_version=${version}" > $version_file"
	echo "rootfs_version=${version}" > $version_file
	#更新build_time
	#	boardinfo_define_file="boardinfo.define"
	#	BUILD_TIME_KEY="rootfs_img_build_time="
	#	BUILD_TIME=`date +"%F_%T"`
	#	echo "$SUDO_PASSWD" | sudo -S sed -i -e "s/^$BUILD_TIME_KEY.*$/$BUILD_TIME_KEY$BUILD_TIME/g" $rootfs_update_path_etc_board/$boardinfo_define_file
	#	#更新根文件系统中的文件
	#	cp $rootfs_update_path_etc_board/$boardinfo_define_file $LPC3250_ETC_BOARD_DEST_PATH/$boardinfo_define_file

	echo "echo "rootfs_img_build_time=`date +"%F_%T"`" >> $version_file"
	echo "rootfs_img_build_time=`date +"%F_%T"`" >> $version_file

}

if [ $# -ne 1 -a $# -ne 2 ]; then
	help
fi



case "$1" in
	$LPC3250_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		generate_version_file $LPC3250_ROOTFS_DEST_PATH
		install_lpc3250
		install_rootfs_update
		;;

	$TCI6614_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		generate_version_file $TCI6614_ROOTFS_DEST_PATH
		install_tci6614
		install_rootfs_update_tci6614
		;;

	$ALL_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		generate_version_file $LPC3250_ROOTFS_DEST_PATH
		install_lpc3250
		install_rootfs_update
		generate_version_file $TCI6614_ROOTFS_DEST_PATH
		install_tci6614
		install_rootfs_update_tci6614
		;;

	$LPC3250_MISC_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		install_lpc3250_misc
		;;

	$UPDATE_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		generate_version_file $LPC3250_ROOTFS_DEST_PATH
		install_rootfs_update
		generate_version_file $TCI6614_ROOTFS_DEST_PATH
		install_rootfs_update_tci6614
		;;
	$LPC3250_UPDATE_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		generate_version_file $LPC3250_ROOTFS_DEST_PATH
		install_rootfs_update
		;;
	$TCI6614_UPDATE_KEY)
		[ $# -ne 2 ] && (echo "please assigned station!";exit)
		station_get $2
		generate_version_file $TCI6614_ROOTFS_DEST_PATH
		install_rootfs_update_tci6614
		;;

	$PACK_SHELL)
		#拷贝打包脚本到相应的目录中
		cp $rootfs_common_path/pack-shell/$cpu_name_lpc3250/*  $LPC3250_DEST_PATH/
		cp $rootfs_common_path/pack-shell/$cpu_name_tci6614/*  $TCI6614_DEST_PATH/
		exit
		;;

	*)
		help
		;;
esac


cp $rootfs_common_path/usr/sbin/rootfs_update.sh /opt/local/$station

exit 0

