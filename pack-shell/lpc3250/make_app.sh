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

#版本前缀
ver_prefix="V1.1."

APP_REPOSITORY_DIR=application/lpc3250
APP_REPOSITORY_ROOTFS_DIR=application/lpc3250_rootfs
CCU_BIN_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$BIN_PATH/CCU
CCU_ETC_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$ETC_PATH/CCU
RRU_BIN_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$BIN_PATH/RRU
RRU_ETC_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$ETC_PATH/RRU
LIB_SRC_PATH=$APP_REPOSITORY_ROOTFS_DIR/$LIB_PATH/

#boarddefine-change.sh 输出结果暂存文件
BOARDDEFINE_INFO_FILE=boarddefine.info
BOARDDEFINE_SHELL=/etc/board/boarddefine-change.sh

#当前路径
NOW_PATH=`pwd`

DEBUG=0
TEST=0


BOARD_LIST=
declare -A HARDWARE='()'

#获取boarddefine-change.sh --info输出结果
echo "$SUDO_PASSWD" | sudo -S $BOARDDEFINE_SHELL --info > $BOARDDEFINE_INFO_FILE

#功能： 获取板名列表
#参数： ccu 或 rru
boardlist_get()
{
	#查找以$1为结尾的字符串
	BOARD_LIST=`sed -n '/^--board_name/ p' $BOARDDEFINE_INFO_FILE | awk '{for(i=1;i<=NF;i++){if($i~/'${1}'$/)print $i}}'|tr '\n' ' '`
}

#功能： 获取hardware列表
#参数： board name
hardwarelist_get()
{
	#echo $1
	#sed -n '/^--hardware.*: \+'${1}'/ p' $BOARDDEFINE_INFO_FILE
	#查找含有$1的字符串
	BOARD_HARDWARE_LIST=`sed -n '/^--hardware.*: \+'${1}'/ p' $BOARDDEFINE_INFO_FILE | awk -F ':' '{print $2}' | awk -F '-' '{print $2}'`
}

svn_repository_info_get()
{
	cd $1
	svn_version="`svn info | sed -n 's,^最后修改的版本: \(.*\),\1,p'`"
	svn_modify_time=`svn info | sed -n 's,^最后修改的时间: \(.*\)+\(.*\),\1,p'`
	cd $NOW_PATH
}

applicationinfo_write()
{
	sys_debug_file="$APP_DIR/$SBIN_PATH/auto_generate_sys_debug"
	#进入到程序顶层目录  注意：rru 与 ccu的顶层目录不同
	echo "applicationinfo_write enter dir:$1"

	#获取cmdline版本
	svn_repository_info_get $1/cmdline/
	app_package_cmdline_ver=$svn_version
	#获取include版本
	svn_repository_info_get $1/include/
	app_package_include_ver=$svn_version
	#获取libs版本
	svn_repository_info_get $1/libs/
	app_package_libs_ver=$svn_version
	#获取modules版本
	svn_repository_info_get $1/modules/
	app_package_modules_ver=$svn_version

	case $2 in
		ccu)
			#获取ccu版本
			svn_repository_info_get $1/CCU/
			app_package_bin_ver=$svn_version
			cd $NOW_PATH
			#获取install版本
			svn_repository_info_get $1/install/opt-ccu/
			#app_package_install_ver=$svn_version
			;;

		rru)
			#获取rru版本
			svn_repository_info_get $1/RRU/
			app_package_bin_ver=$svn_version
			#获取install版本
			svn_repository_info_get $1/install/opt-rru/
			#app_package_install_ver=$svn_version
			;;
		*)
			echo "applicationinfo_write: invalid param $2"
			;;
	esac
	#获取svn版本相关信息
	svn_repository_info_get $1
	app_package_ver=$svn_version
	app_modify_time=$svn_modify_time
	echo "applicationinfo_write exit dir:$1"
	
	#更新应用程序信息
	echo -n "" > "$sys_debug_file"
	echo "${APP_PACKAGE_VERSION_KEY}=${ver_prefix}${app_package_ver}" >> "$sys_debug_file"
	echo "application_package_bin_version=${ver_prefix}${app_package_bin_ver}" >> "$sys_debug_file"
	echo "application_package_lib_version=${ver_prefix}${app_package_libs_ver}" >> "$sys_debug_file"
	echo "application_package_modules_version=${ver_prefix}${app_package_modules_ver}" >> "$sys_debug_file"
	echo "application_package_intall_version=${ver_prefix}${app_package_install_ver}" >> "$sys_debug_file"
	echo "application_package_cmdline_version=${ver_prefix}${app_package_cmdline_ver}" >> "$sys_debug_file"
	echo "application_package_include_version=${ver_prefix}${app_package_include_ver}" >> "$sys_debug_file"

	#sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_VERSION_KEY}".*/    echo \""${APP_PACKAGE_VERSION_KEY}"="${ver_prefix}""${app_package_ver}"\" >> \$1/" $2
	#echo "$APP_PACKAGE_VERSION_KEY=${ver_prefix}${app_package_ver}"

	#sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_MODIFY_TIME_KEY}".*/    echo \""${APP_PACKAGE_MODIFY_TIME_KEY}"=""${app_modify_time}""\" >> \$1/" $2
	#echo "$APP_PACKAGE_MODIFY_TIME_KEY=$app_modify_time"

	##更新应用程序信息
	#sed '1d;s/\\n//g;s/\\t//g;s/\\//g;s/^[[:space:]]*//g;s/"//g' $1 > $TMP_FILE
	#echo "application info file: $2"
	#
	#while read line
	#do
	#	#echo   "$line" 
	#	case "$line" in
	#		*"VERSION"* )
	#			read value
	#			sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_VERSION_KEY}".*/    echo \""${APP_PACKAGE_VERSION_KEY}"="${value}"\" >> \$1/" $2
	#			echo "application_package_version=$value"
	#		;;
	#		*"MODIFY TIME"* )
	#			read value
	#			sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_MODIFY_TIME_KEY}".*/    echo \""${APP_PACKAGE_MODIFY_TIME_KEY}"=""${value}""\" >> \$1/" $2
	#			echo "application_package_modify_time=$value"
	#		;;
	#		*"BUILD TIME"* )
	#			read value
	#			sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${APP_PACKAGE_BUILD_TIME_KEY}".*/    echo \""${APP_PACKAGE_BUILD_TIME_KEY}"=""${value}""\" >> \$1/" $2
	#			echo "application_package_build_time=$value"
	#		;;
	#		*)
	#			#echo "invalid key"
	#			#exit 1
	#	esac

	#done  < $TMP_FILE

	#rm -rf $TMP_FILE

	BUILD_TIME=`date +"%F %T"`
	#sed -i "/^"${SYS_SECTION_KEY}"/,/^}/ s/.*"${BUILD_TIME_KEY}".*/    echo \""${BUILD_TIME_KEY}"=""${BUILD_TIME}""\" >> \$1/" $2
	echo "${BUILD_TIME_KEY}=${BUILD_TIME}" >> "$sys_debug_file"
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
	[ $TEST -eq 1 ] && APP_DIR=history/opt-ccu/ || APP_DIR=opt-ccu/
	FPGA_OPT_REPOSITORY_PATH=/opt/repository/lte-ccu
	FPGA_NAME=dpd_module.bit
	APP_PROC_FILE=$APP_DIR/opt/itl/sbin/itl-sys-proc
	HARDWARE='()'

	#板名列表
	boardlist_get ccu
	echo "board list = $BOARD_LIST"
	#获取hardware列表
	for i in $BOARD_LIST;
	do
		hardwarelist_get $i		
		HARDWARE[$i]="$BOARD_HARDWARE_LIST"
		echo "$i hardware list  = ${HARDWARE[$i]}"
	done
}

build_ccu()
{
	PARTION_NAME=app-ccu.img
	APP_TAR_NAME=app-ccu.tar.gz
	APP_SRC_DIR=$APP_REPOSITORY_DIR

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
	applicationinfo_write $APP_SRC_DIR ccu
	[ $DEBUG -eq 0 ] && ./_make_app.sh $APP_DIR $PARTION_NAME $PARTION_SIZE $APP_TAR_NAME 
}

rru_prepare()
{
	[ $TEST -eq 1 ] && APP_DIR=history/opt-rru/ || APP_DIR=opt-rru/
	FPGA_OPT_REPOSITORY_PATH=/opt/repository/lte-rru
	FPGA_NAME=dpd_module.bit
	APP_PROC_FILE=$APP_DIR/opt/itl/sbin/itl-sys-proc
	HARDWARE='()'

	#板名列表
	boardlist_get rru
	echo "board list = $BOARD_LIST"
	#获取hardware列表
	for i in $BOARD_LIST;
	do
		hardwarelist_get $i		
		HARDWARE[$i]="$BOARD_HARDWARE_LIST"
		echo "$i hardware list  = ${HARDWARE[$i]}"
	done
}

build_rru()
{
	PARTION_NAME=app-rru.img
	APP_TAR_NAME=app-rru.tar.gz
	APP_SRC_DIR=$APP_REPOSITORY_DIR

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
	applicationinfo_write $APP_SRC_DIR rru
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
