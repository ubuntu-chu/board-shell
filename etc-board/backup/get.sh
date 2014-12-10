#!/bin/sh

tftp -g -r cpu-identify.sh 192.192.192.201
tftp -g -r rcS  192.192.192.201
tftp -g -r rcS.define 192.192.192.201
tftp -g -r boardinfo.define 192.192.192.201
tftp -g -r validate-boardinfo.sh 192.192.192.201
#tftp -g -r itl-sys-proc 192.192.192.201&&mv  itl-sys-proc /opt/itl/sbin/itl-sys-proc&&chmod a+x /opt/itl/sbin/itl-sys-proc
tftp -g -r configuration-parse.sh 192.192.192.201&&chmod a+x configuration-parse.sh
tftp -g -r proc-module.ko 192.192.192.201

