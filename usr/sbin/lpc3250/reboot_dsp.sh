#!/bin/sh

RESET_REG=404
RESET_REG_VALUE=0x55aa

which wr > /dev/null
if [ $? -ne 0 ]; then
	echo "wr can not find!"
	exit 2
fi

echo "write fpga_reg($RESET_REG) = $RESET_REG_VALUE to reboot dsp"
wr $RESET_REG $RESET_REG_VALUE

exit 0





