#!/bin/sh

#time=`date +"%F_%H-%M-%S"`
time=`date +"%F_%H-%M"`

server_path="zhangxu@gitserver:D:/ICW/project/lte"

push_to_server()
{
	tar -zcvf $1 $2
	echo "scp $1 $server_path/$3/$1_$time"
	scp $1 $server_path/$3/$1_$time

}

push_to_server  rootfs.tar.gz  rootfs tci6614/rootfs 
push_to_server  rootfs_recovery.tar.gz  rootfs_recovery tci6614/rootfs 

cd lpc3250


push_to_server  rootfs.tar.gz  rootfs lpc3250/rootfs 


#tar -zcvf rootfs.tar.gz rootfs
#echo "scp rootfs.tar.gz $server_path/tci6614/rootfs/rootfs.tar.gz_$time"
#scp rootfs.tar.gz $server_path/tci6614/rootfs/rootfs.tar.gz_$time
#
#tar -zcvf rootfs_recovery.tar.gz rootfs_recovery
#echo "scp rootfs_recovery.tar.gz $server_path/tci6614/rootfs/rootfs_recovery.tar.gz_$time"
#scp rootfs_recovery.tar.gz $server_path/tci6614/rootfs/rootfs_recovery.tar.gz_$time
#
#
#cd lpc3250
#
#tar -zcvf rootfs.tar.gz rootfs
#echo "scp rootfs.tar.gz $server_path/lpc3250/rootfs/rootfs.tar.gz_$time"
#scp rootfs.tar.gz $server_path/lpc3250/rootfs/rootfs.tar.gz_$time
#

