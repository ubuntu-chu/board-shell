#!/bin/bash
#

etc_board_rcs_file=/etc/board/rcS
if [ ! -e $etc_board_rcs_file ]; then
	echo "$etc_board_rcs_file do not exist!"
	exit 1
fi
. $etc_board_rcs_file

network_name_key="network_name"
param_network_name="--$network_name_key"
param_nic_name="--nic"
address_key="address"
param_address="--$address_key"
netmask_key="netmask"
param_netmask="--$netmask_key"
gateway_key="gateway"
param_gateway="--$gateway_key"
network_key="network"
param_network="--$network_key"
hwaddress_key="hwaddress"
param_hwaddress="--$hwaddress_key"
param_current="--current"
param_help="--help"
param_debug="--debug"

DEBUG=0
NETWORK_NAME=
ADDRESS=
NETMASK=
GATEWAY=
NETWORK=
HWADDRESS=
NIC_NAME=

cur_network_name=
priv_temp_file=/var/run/$$.tmp_priv
line_no=()
nic_index=0

section_get()
{
	#去除=号左右的空格
	awk '/^'${1}'=\{/,/^\}/ {print $0 >> "'"${3}"'"}' "${2}"
}

help()
{
	echo "Usage            : $0 <$param_network_name|$param_nic_name|$param_address|$param_debug|$param_netmask|$param_gateway|$param_network|$param_hwaddress>"
	echo "Param $param_help: show help"
	echo "Param $param_debug: enable debug"
	echo "Param $param_network_name: network name; you can git it var boardinfo command"
	echo "Param $param_nic_name: network card name; you can get it var ifconfig command"
	echo "Param $param_address: ip address"
	echo "Param $param_netmask: net mask"
	echo "Param $param_gateway: gateway"
	echo "Param $param_network: network address"
	echo "Param $param_hwaddress: mac address"
	
	exit 0
}

show_current()
{
	echo -n "" > $SHELL_TEMP_SYS_FILE
	echo ""
	echo "network name: $cur_network_name"
	echo ""
	section_get $cur_network_name $BOARD_INFO_SRC_FILE $SHELL_TEMP_SYS_FILE
	cat $SHELL_TEMP_SYS_FILE
	echo ""
	exit 0
}

if [ $# -eq 0 ]; then
	help
fi

station_change_shell="station-change.sh"
have_valid_station=0
which $station_change_shell > /dev/null
if [ $? -eq 0 ]; then
	#获取当前配置信息
	current_station=`$station_change_shell --current_simple`
	if [ $? -eq 0 ]; then
		if [ ! -z $current_station ]; then
			#具有合法值 
			have_valid_station=1
		fi
	fi
fi

if [ $have_valid_station -eq 0 ]; then
	echo "system do not have a valid station! boardinfo write error! please check what happened!"
	exit 1
fi

SHELL_TEMP_SYS_FILE=/var/run/$$.tmp
if [ -z $BOARD_INFO_FILE ]; then
	BOARD_INFO_FILE=/var/run/boardinfo
fi

echo -n "" > $SHELL_TEMP_SYS_FILE
#获取当前网络配置名字
section_get debug $BOARD_INFO_FILE $SHELL_TEMP_SYS_FILE
proc_line_return $NETWORK_KEY $SHELL_TEMP_SYS_FILE
if [ $? -eq 0 ]; then
	cur_network_name=$PROC_LINE_VALUE
else
	echo "cur network name do not exist! please check what happened!"
	exit 1
fi


#解析所有参数
while [ $# -gt 0 ]; 
do    
	case "$1" in
		$param_debug)
			# 是 "-d" 或 "--debug" 参数?
			DEBUG=1
			;;
		$param_network_name)
			NETWORK_NAME="$2"
			shift
			;;
		$param_nic_name)
			NIC_NAME="$2"
			shift
			;;
		$param_address)
			ADDRESS="$2"
			shift
			;;
		$param_netmask)
			NETMASK="$2"
			shift
			;;
		$param_gateway)
			GATEWAY="$2"
			shift
			;;
		$param_network)
			NETWORK="$2"
			shift
			;;
		$param_hwaddress)
			HWADDRESS="$2"
			shift
			;;
		$param_current)
			show_current
			;;
		$param_help)
			help
			;;
		*)
			echo "$1 : invalid param! please check!"
			exit 2
			;;
	esac
	# 检查剩余的参数.
	shift       
done


if [ -z $NIC_NAME ]; then
	echo "nic name is null, please assigned a valid nic name!"
	exit 1
fi

#若制定了网络名字 则使用指定的名称
if [ ! -z $NETWORK_NAME ]; then
	cur_network_name=$NETWORK_NAME
fi

debug echo "cur network name: $cur_network_name"

echo -n "" > $SHELL_TEMP_SYS_FILE
section_get $cur_network_name $BOARD_INFO_SRC_FILE $SHELL_TEMP_SYS_FILE
#获取网络配置文件总行数
total_line=`wc -l $SHELL_TEMP_SYS_FILE|awk -F ' ' '{print $1}'`
debug echo "total_line=$total_line"

#获取网卡个数
cat $SHELL_TEMP_SYS_FILE| egrep ".*iface.*" -n > $priv_temp_file
nic_num=`wc -l $priv_temp_file|awk -F ' ' '{print $1}'`

debug echo "nic_num=$nic_num"

#判断nic名字是否合法
grep "$NIC_NAME" $priv_temp_file > /dev/null
if [ $? -ne 0 ]; then
	echo "nic name($NIC_NAME) is invalid, please check!"
	exit 1
fi

if [ "lo" = "$NIC_NAME" ]; then
	echo "nic name($NIC_NAME) is lo, this is not allowed!"
	exit 4
fi

#依据nic名字 找到合法的配置行数范围
index=0
hit=0
nic_index=0
while read line
do
	debug echo $line
	line_no[$index]=`echo $line | cut -d ':' -f 1`
	for item in $line;
	do
		if [ $item = $NIC_NAME ]; then
			if [ $hit -eq 0 ]; then
				hit=1		
				nic_index=$index
			else
				echo "nic name($NIC_NAME) have more than one, please check what happened!"
				exit 2
			fi
		fi
	done
	index=$(($index + 1))
done  < $priv_temp_file

debug echo ${line_no[*]}

#获取修改范围
begin_line_no=${line_no[$nic_index]}
line_no_index=$((${#line_no[*]} - 1))
if [ $nic_index -eq  $line_no_index ]; then
	end_line_no=$total_line
else
	end_line_no=${line_no[$(($nic_index + 1))]}
fi

debug echo "begin_line_no=$begin_line_no"
debug echo "end_line_no=$end_line_no"
padding_space="      "

if [ ! -z $ADDRESS ]; then
	sed -i "$begin_line_no,$end_line_no s/^[ \t ]*"${address_key}".*/""${padding_space}"""${address_key}" "${ADDRESS}"/g" $SHELL_TEMP_SYS_FILE	
fi

if [ ! -z $NETMASK ]; then
	sed -i "$begin_line_no,$end_line_no s/^[ \t ]*"${netmask_key}".*/""${padding_space}"""${netmask_key}" "${NETMASK}"/g" $SHELL_TEMP_SYS_FILE	
fi

if [ ! -z $GATEWAY ]; then
	sed -i "$begin_line_no,$end_line_no s/^[ \t ]*"${gateway_key}".*/""${padding_space}"""${gateway_key}" "${GATEWAY}"/g" $SHELL_TEMP_SYS_FILE	
fi

if [ ! -z $NETWORK ]; then
	sed -i "$begin_line_no,$end_line_no s/^[ \t ]*"${network_key}".*/""${padding_space}"""${network_key}" "${NETWORK}"/g" $SHELL_TEMP_SYS_FILE	
fi

if [ ! -z $HWADDRESS ]; then
	#检测是否有ether关键字
	ether_key="ether"
	sed -n "$begin_line_no,$end_line_no p" $SHELL_TEMP_SYS_FILE	| grep "$ether_key"  > /dev/null
	if [ $? -eq 0 ]; then
		sed -i "$begin_line_no,$end_line_no s/^[ \t ]*"${hwaddress_key}".*/""${padding_space}"""${hwaddress_key}" "${ether_key}" "${HWADDRESS}"/g" $SHELL_TEMP_SYS_FILE	
	else
		sed -i "$begin_line_no,$end_line_no s/^[ \t ]*"${hwaddress_key}".*/""${padding_space}"""${hwaddress_key}" "${HWADDRESS}"/g" $SHELL_TEMP_SYS_FILE	
	fi

fi

#将原先的区段删除   再在指定的位置上 添加新的定义
#sed -i "/^"${cur_network_name}"={/,/^\}/ d\
#		;"${line_no}" r "${SHELL_TEMP_SYS_FILE}"" $BOARD_INFO_SRC_FILE

#更改boardinfo.define文件中相应配置

value=`grep -n "${cur_network_name}={"  $BOARD_INFO_SRC_FILE`
if [ $? -ne 0 ]; then
	echo "$BOARD_INFO_SRC_FILE donot have ${cur_network_name} line"
	exit 1
fi
line_no=`echo $value|cut -d ':' -f1`

debug echo "match line no = $line_no"
line_no=$(($line_no-1))

echo "modify file:${BOARD_ENTRY_SHELL_PATH}/${current_station}/${BOARD_INFO_DEFINE_FILE}"
(cd ${BOARD_ENTRY_SHELL_PATH}&&ln -sf ${current_station}/${BOARD_INFO_DEFINE_FILE} ${BOARD_INFO_DEFINE_FILE}) 
sed -i "/^"${cur_network_name}"={/,/^\}/ d\
		;"${line_no}" r "${SHELL_TEMP_SYS_FILE}"" ${BOARD_ENTRY_SHELL_PATH}/${current_station}/${BOARD_INFO_DEFINE_FILE}
rm -rf $priv_temp_file
rm -rf $SHELL_TEMP_SYS_FILE

echo "network change success"
echo "you can run /etc/board/validate-boardinfo.sh to view new boardinfo"
echo "when you make sure that the network configuration is correct, you can press <reboot> to let the network configuration take effect!"

