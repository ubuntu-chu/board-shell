#!/bin/sh

cd /var/flash
echo "umount /opt"
umount /opt

#/dev/mtd6 使用 ubi文件系统
echo "ubidetach -m 6"
ubidetach -m 6 

exit $?




