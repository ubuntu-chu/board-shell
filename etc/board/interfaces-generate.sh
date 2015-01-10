#!/bin/bash
#
# generate network interfaces file
#
# 

. /etc/board/rcS

#参数为  network名字 
generate_network_interface()
{
	echo -n > $INTERFACES_DEST_FILE
	echo "# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)" >> $INTERFACES_DEST_FILE
	echo "" >> $INTERFACES_DEST_FILE

	#过程： 查找以NETWORK_KEY为开始，以}为结尾的所有行
	#       在这些行中取出第一行和最后一行，并删除行首的空格
	#       将这些行写入到文件中
	cat ${INTERFACES_SRC_FILE} | awk '/^'${1}'=\{/,/^\}/ {print $0}' \
		| sed '1d;$d;s/^[[:space:]]*//'                              \
		| awk '{print $0 >> "'"${INTERFACES_DEST_FILE}"'"}'

	echo "" >> $INTERFACES_DEST_FILE
	echo "" >> $INTERFACES_DEST_FILE
}

if [ "$1" = "start" ]; then
	echo "Generating /etc/network/interface..."
	generate_network_interface ${NETWORK_KEY}
fi

