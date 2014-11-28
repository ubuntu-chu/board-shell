#!/bin/bash


configuration_parse(){
	BOARD_INFO_REG=0x00
	FPGA_VER_REG=0x01
	VER_YEAR_REG=0x02
	VER_DATE_REG=0x03
	CASE_SLOT_REG=0x05
	SYS_REG_VER_REG=0x0f

	#解析系统寄存器版本 bit: 15:12
	proc_line $SYS_REG_VER_REG $2
	SYS_REG_VER=$((${PROC_LINE_VALUE} & 0xf000))
	let "SYS_REG_VER=$SYS_REG_VER >> 12"
	debug echo "sys_reg_ver = $SYS_REG_VER"

	case "$SYS_REG_VER" in
		"0")
			#此处做系统寄存器兼容处理
			;;

		"*")
			;;
	esac

	case "$1" in
		"board_id")
			#解析出slot_id值   slot_id在0x05寄存器的低三位
			proc_line $CASE_SLOT_REG $2
			BOARD_ID=$((${PROC_LINE_VALUE} & 0x07))
			;;

		"all")
			echo "sys_regs={" >> $3
			echo "    [0]={" >> $3
			#解析出所有值 并写入到指定文件
			proc_line $BOARD_INFO_REG $2
			#bit0-bit3  料单号
			value=$((${PROC_LINE_VALUE} & 0x000f))
			echo "        bom_version=${value}" >> $3
			#bit4-bit7  pcb版本号
			value=$((${PROC_LINE_VALUE} & 0x00f0))
			let "value=$value >> 4"
			echo "        pcb_version=${value}" >> $3
			#bit8-bit15  板类型
			value=$((${PROC_LINE_VALUE} & 0xff00))
			let "value=$value >> 8"
			echo "        board_type=${value}" >> $3

			proc_line $FPGA_VER_REG $2
			PROC_LINE_VALUE=`printf "0x%04x" ${PROC_LINE_VALUE}`
			echo "        logic_version=${PROC_LINE_VALUE}" >> $3

			proc_line $VER_YEAR_REG $2
			PROC_LINE_VALUE=`printf "0x%04x" ${PROC_LINE_VALUE}`
			echo "        logic_year=${PROC_LINE_VALUE}" >> $3

			proc_line $VER_DATE_REG $2
			PROC_LINE_VALUE=`printf "0x%04x" ${PROC_LINE_VALUE}`
			echo "        logic_date=${PROC_LINE_VALUE}" >> $3
			proc_line $CASE_SLOT_REG $2
			#槽位号
			SLOT_ID=$((${PROC_LINE_VALUE} & 0x07))
			echo "        slot_id=${SLOT_ID}" >> $3
			#bit8 bit9 机架
			RACK_TYPE=$((${PROC_LINE_VALUE} & 0x07))
			let "RACK_TYPE=$RACK_TYPE >> 8"
			echo "        rack_type=${RACK_TYPE}" >> $3
			echo "        sys_regs_version=${SYS_REG_VER}" >> $3
			echo "    }," >> $3

			echo "}" >> $3
			;;

		"*")
			return 1;
			;;
	esac

	return 0
	
}




