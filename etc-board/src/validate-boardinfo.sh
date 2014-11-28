#!/bin/sh

bash /etc/board/cpu-identify.sh start

echo "cat $BOARD_INFO_FILE"
cat $BOARD_INFO_FILE

