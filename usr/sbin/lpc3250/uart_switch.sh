#!/bin/sh

DSP_ID_1="bbu"
DSP_ID_2="mesh"
CCU_ID="ccu"
COM_SEL_REG=408
COM_SEL_REG_VALUE_DSP_ID_1=1
COM_SEL_REG_VALUE_DSP_ID_2=2
COM_SEL_REG_VALUE_CCU_ID=0

trap "trap_int" INT

help() 
{
	echo "Usage                 : $0 <com_sel>" 
	echo "Param com_sel         : [$DSP_ID_1|$DSP_ID_2|$CCU_ID]"
	exit 1
}

which wr > /dev/null
if [ $? -ne 0 ]; then
	echo "wr can not find!"
	exit 2
fi

if [ $# -ne 1 ]; then
	help
fi

case $1 in
	$DSP_ID_1)
		COM_SEL_REG_VALUE=$COM_SEL_REG_VALUE_DSP_ID_1
		;;

	$DSP_ID_2)
		COM_SEL_REG_VALUE=$COM_SEL_REG_VALUE_DSP_ID_2
		;;

	$CCU_ID)
		COM_SEL_REG_VALUE=$COM_SEL_REG_VALUE_CCU_ID
		;;

	*)
		help
		;;
esac

echo "write fpga_reg($COM_SEL_REG) = $COM_SEL_REG_VALUE to select $1 com"
wr $COM_SEL_REG $COM_SEL_REG_VALUE

exit 0


