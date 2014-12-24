#!/bin/sh

DSP_ID_1="bbu"
DSP_ID_1_BOOT_REG=412
DSP_ID_2="mesh"
DSP_ID_2_BOOT_REG=416
DSP_ID_ALL="all"
RESET_REG=404
RESET_REG_VALUE=0x55aa
BOOT_REG_VALUE_NETBOOT=1
BOOT_REG_VALUE_SWITCH=0
COM_SEL_REG=408
COM_SEL_REG_VALUE_DSP_ID_1=1
COM_SEL_REG_VALUE_DSP_ID_2=2

trap "trap_int" INT

help() 
{
	echo "Usage                 : $0 <dsp_id>" 
	echo "Param dsp_id          : [$DSP_ID_1|$DSP_ID_2|$DSP_ID_ALL]"
	exit 1
}

trap_int()
{
	echo "please press 'q' to quit"
}

netboot()
{

	if [ $1 = $DSP_ID_1 ]; then
		BOOT_REG=$DSP_ID_1_BOOT_REG
		COM_SEL_REG_VALUE=$COM_SEL_REG_VALUE_DSP_ID_1
	elif [ $1 = $DSP_ID_2 ]; then
		BOOT_REG=$DSP_ID_2_BOOT_REG
		COM_SEL_REG_VALUE=$COM_SEL_REG_VALUE_DSP_ID_2
        fi
	
	echo "write fpga_reg($COM_SEL_REG) = $COM_SEL_REG_VALUE to select $1 com"
	wr $COM_SEL_REG $COM_SEL_REG_VALUE
	sleep 1
	
	echo "write fpga_reg($BOOT_REG) = $BOOT_REG_VALUE_NETBOOT to enable $1 netboot config"
	wr $BOOT_REG $BOOT_REG_VALUE_NETBOOT
	sleep 1

	echo "write fpga_reg($RESET_REG) = $RESET_REG_VALUE to reboot $1"
	wr $RESET_REG $RESET_REG_VALUE

	while true
	do
		echo "when the netboot finish, press 'y' to continue. press 'q' to quit."  
		read keypress 
		case "$keypress" in  
		  "y"|"Y" ) 
			  break
			  ;;  
		  "q"|"Q" ) 
			  #echo "please restart(power off and power on) the lte to enable the switch config"
			  wr $BOOT_REG $BOOT_REG_VALUE_SWITCH
			  echo "$SHELL_NAME quit!"
			  exit 3
			  ;;  
		  * ) 
			  echo "invalid input! please input again"
			  continue
			  ;;

		esac
	done

	echo "write fpga_reg($BOOT_REG) = $BOOT_REG_VALUE_SWITCH to enable $1 switch config"
	wr $BOOT_REG $BOOT_REG_VALUE_SWITCH

	echo "write fpga_reg($RESET_REG) = $RESET_REG_VALUE to reboot $1"
	wr $RESET_REG $RESET_REG_VALUE

	echo "--------------$1 done!--------------"
}

which wr > /dev/null
if [ $? -ne 0 ]; then
	echo "wr can not find!"
	exit 2
fi

if [ $# -ne 1 ]; then
	help
fi

SHELL_NAME=$0

case "$1" in
	$DSP_ID_1|$DSP_ID_2 )
		netboot $1;;
	$DSP_ID_ALL )
		netboot $DSP_ID_1
		sleep 1
		netboot $DSP_ID_2;;
	* )
		help
esac

exit 0





