#!/bin/bash

MAKE_KEY="make"
FPGA_KEY="fpga"
CCU_KEY="ccu"
RRU_KEY="rru"
ALL_KEY="all"
BUILD_TIME_KEY="app_img_build_time="
#分区大小 280M
PARTION_SIZE=0x11800000

help(){
	echo "Usage                 : $0 <$CCU_KEY|$RRU_KEY|$ALL_KEY|$MAKE_KEY>"
	exit 1

}

if [ $# -ne 1  ]; then
	help
fi

APP_PACKAGE_VERSION_KEY="application_package_version"
APP_PACKAGE_MODIFY_TIME_KEY="application_package_modify_time"
APP_PACKAGE_BUILD_TIME_KEY="application_package_build_time"
SYS_SECTION_KEY="sys_debug()"
TMP_FILE=make_app_tmp.h
BUILD_TIME_KEY="app_img_build_time"
SBIN_PATH=opt/itl/sbin
BIN_PATH=opt/itl/bin
LIB_PATH=opt/itl/lib
ETC_PATH=opt/itl/etc
FPGA_PATH=opt/itl/fpga
HARDWARE_KEY=hardware
APP_DIR=history/opt-ccu/
FPGA_OPT_REPOSITORY_PATH=/opt/repository/lte-ccu
FPGA_NAME=dpd_module.bit
FPGA_PARAM="fpga_copy"

APP_REPOSITORY_DIR=application/lpc3250
APP_REPOSITORY_ROOTFS_DIR=application/lpc3250_rootfs
CCU_BIN_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$BIN_PATH/CCU
CCU_ETC_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$ETC_PATH/CCU
RRU_BIN_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$BIN_PATH/RRU
RRU_ETC_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$ETC_PATH/RRU
LIB_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$LIB_PATH/

DEBUG=0


BOARD_LIST=
declare -A HARDWARE='()'

applicationinfo_write()
{
	#更新应用程序信息
	sed '1d;s/\\n//g;s/\\t//g;s/\\//g;s/^[[:space:]]*//g;s/"//g' $1 > $TMP_FILE
	
	while read line
	do
		#echo   "$line" 
		case "$line" in
			*"VERSION"* )
				read value
				sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_VERSION_KEY}".*/    echo \""${APP_PACKAGE_VERSION_KEY}"="${value}"\" >> \$1/" $2
				echo "application_package_version=$value"
			;;
			*"MODIFY TIME"* )
				read value
				sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_MODIFY_TIME_KEY}".*/    echo \""${APP_PACKAGE_MODIFY_TIME_KEY}"=""${value}""\" >> \$1/" $2
				echo "application_package_modify_time=$value"
			;;
			*"BUILD TIME"* )
				read value
				sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_BUILD_TIME_KEY}".*/    echo \""${APP_PACKAGE_BUILD_TIME_KEY}"=""${value}""\" >> \$1/" $2
				echo "application_package_build_time=$value"
			;;
			*)
				#echo "invalid key"
				#exit 1
		esac

	done  < $TMP_FILE

	rm -rf $TMP_FILE

	BUILD_TIME=`date +"%F %T"`
	sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${BUILD_TIME_KEY}".*/    echo \""${BUILD_TIME_KEY}"=""${BUILD_TIME}""\" >> \$1/" $2
}

boardfiles_prepare()
{
	echo "app dir = $APP_DIR"

	for i in $BOARD_LIST;
	do
		echo "boardname = $i"
		hardware_list=${HARDWARE[$i]}
		echo "hardware_list = $hardware_list"

		for j in $hardware_list;
		do
			hardware_dir=$APP_DIR/$SBIN_PATH/$i/$HARDWARE_KEY-$j
			if [ ! -d "$hardware_dir" ]; then
				mkdir -p $hardware_dir	
			fi

			hardware_dir=$APP_DIR/$FPGA_PATH/$i/$HARDWARE_KEY-$j
			if [ ! -d "$hardware_dir" ]; then
				mkdir -p $hardware_dir	
			fi

			fpga_dir=$FPGA_OPT_REPOSITORY_PATH/$i/$HARDWARE_KEY-$j
			if [ ! -d "$fpga_dir" ]; then
				mkdir -p $fpga_dir	
			fi
			if [ $# -eq 1 ]; then
				if [ $1 = "$FPGA_PARAM" ]; then
					fpga_file=$fpga_dir/$FPGA_NAME
					if [ -e "$fpga_file" ]; then
						echo "cp $fpga_file $hardware_dir/"
						cp $fpga_file $hardware_dir/
					fi
				fi
			fi
		done
	done
}

ccu_prepare()
{
	#APP_DIR=history/opt-ccu/
	APP_DIR=opt-ccu/
	FPGA_OPT_REPOSITORY_PATH=/opt/repository/lte-ccu
	FPGA_NAME=dpd_module.bit

	BOARD_LIST="ifu_ccu rs_ccu"
	#多个值之间要以空格分隔 并加上双引号
	HARDWARE[ifu_ccu]="1" 
	HARDWARE[rs_ccu]="1"
}

build_ccu()
{
	PARTION_NAME=app-ccu.img
	APP_TAR_NAME=app-ccu.tar.gz
	APP_PROC_FILE=$APP_DIR/opt/itl/sbin/itl-sys-proc
	APP_VERSION_FILE=$APP_REPOSITORY_DIR/version.h

	#准备工作
	ccu_prepare
	#创建板名 硬件版本相关的所有文件
	boardfiles_prepare

	#将程序 库拷贝到指定目录
	echo "rm -rf $APP_DIR/$LIB_PATH/*"
	[ $DEBUG -eq 0 ] && rm -rf $APP_DIR/$LIB_PATH/*

	echo "cp -ar $LIB_SRC_PATH/* $APP_DIR/$LIB_PATH/"
	[ $DEBUG -eq 0 ] && cp -ar $LIB_SRC_PATH/* $APP_DIR/$LIB_PATH/

	echo "cp -ar $CCU_ETC_SRC_PATH/* $APP_DIR/$ETC_PATH/"
	[ $DEBUG -eq 0 ] && cp -ar $CCU_ETC_SRC_PATH/* $APP_DIR/$ETC_PATH/

	echo "rm -rf $APP_DIR/$BIN_PATH/*"
	[ $DEBUG -eq 0 ] && rm -rf $APP_DIR/$BIN_PATH/*

	echo "cp -ar $CCU_BIN_SRC_PATH/* $APP_DIR/$BIN_PATH/"
	[ $DEBUG -eq 0 ] && cp -ar $CCU_BIN_SRC_PATH/* $APP_DIR/$BIN_PATH/

	#更新应用程序信息
	applicationinfo_write $APP_VERSION_FILE $APP_PROC_FILE
	[ $DEBUG -eq 0 ] && ./_make_app.sh $APP_DIR $PARTION_NAME $PARTION_SIZE $APP_TAR_NAME 
}

rru_prepare()
{
	#APP_DIR=history/opt-rru/
	APP_DIR=opt-rru/
	FPGA_OPT_REPOSITORY_PATH=/opt/repository/lte-rru
	FPGA_NAME=dpd_module.bit

	BOARD_LIST="rfu_rru cs_rfu_rru ss_rfu_rru"
	#多个值之间要以空格分隔 并加上双引号
	HARDWARE[rfu_rru]="3" 
	HARDWARE[cs_rfu_rru]="1"
	HARDWARE[ss_rfu_rru]="1"
}

build_rru()
{
	PARTION_NAME=app-rru.img
	APP_TAR_NAME=app-rru.tar.gz
	APP_PROC_FILE=$APP_DIR/opt/itl/sbin/itl-sys-proc
	APP_VERSION_FILE=$APP_REPOSITORY_DIR/version.h

	#准备工作
	rru_prepare
	#创建板名 硬件版本相关的所有文件
	boardfiles_prepare

	#将程序 库拷贝到指定目录
	echo "rm -rf $APP_DIR/$LIB_PATH/*"
	[ $DEBUG -eq 0 ] && rm -rf $APP_DIR/$LIB_PATH/*

	echo "cp -ar $LIB_SRC_PATH/* $APP_DIR/$LIB_PATH/"
	[ $DEBUG -eq 0 ] && cp -ar $LIB_SRC_PATH/* $APP_DIR/$LIB_PATH/

	echo "cp -ar $RRU_ETC_SRC_PATH/* $APP_DIR/$ETC_PATH/"
	[ $DEBUG -eq 0 ] && cp -ar $RRU_ETC_SRC_PATH/* $APP_DIR/$ETC_PATH/

	echo "rm -rf $APP_DIR/$BIN_PATH/*"
	[ $DEBUG -eq 0 ] && rm -rf $APP_DIR/$BIN_PATH/*

	echo "cp -ar $RRU_BIN_SRC_PATH/* $APP_DIR/$BIN_PATH/"
	[ $DEBUG -eq 0 ] && cp -ar $RRU_BIN_SRC_PATH/* $APP_DIR/$BIN_PATH/

	#更新应用程序信息
	applicationinfo_write $APP_VERSION_FILE $APP_PROC_FILE
	[ $DEBUG -eq 0 ] && ./_make_app.sh $APP_DIR $PARTION_NAME $PARTION_SIZE $APP_TAR_NAME 
}

case "$1" in
	$CCU_KEY)
		build_ccu
		;;

	$RRU_KEY)
		build_rru
		;;

	$ALL_KEY)
		build_rru
		build_ccu
		;;

	$MAKE_KEY)
		(cd $APP_REPOSITORY_DIR && svn up && echo "make clean && make 2>make.log && make install 2>make_install.log && exit" | sb2)
		#(cd $APP_REPOSITORY_DIR && svn up && echo "make 2>make.log && make install 2>make_install.log && exit" | sb2)

		echo ""
		echo ""
		echo ""

		egrep -C3 "错误|error|svn" $APP_REPOSITORY_DIR/make.log 
		if [ $? -eq 0 ]; then
			echo "make report error!"
		fi
		egrep -C3 "错误|error|svn" $APP_REPOSITORY_DIR/make_install.log 
		if [ $? -eq 0 ]; then
			echo "make install report error!"
		fi
		;;

	$FPGA_KEY)
		ccu_prepare
		boardfiles_prepare "$FPGA_PARAM"

		rru_prepare
		boardfiles_prepare "$FPGA_PARAM"
		;;

	*)
		help
		;;
esac

exit 0
