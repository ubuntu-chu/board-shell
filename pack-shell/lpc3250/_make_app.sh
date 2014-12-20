#!/bin/sh

APP_DIR=$1
PARTION_NAME=$2
#分区大小 
PARTION_SIZE=$3
APP_TAR_NAME=$4

PARTION_DIR=$APP_DIR

./make_jffs2.sh $PARTION_DIR/opt $PARTION_NAME $PARTION_SIZE 

CURRENT_PATH=`pwd`

cd $APP_DIR
echo "tar zcvf $CURRENT_PATH/$APP_TAR_NAME ./ --exclude=.svn --exclude=.git --exclude=.gitignore"
tar zcvf $CURRENT_PATH/$APP_TAR_NAME ./ --exclude=.svn --exclude=.git --exclude=.gitignore

cd $CURRENT_PATH

if [ -z ${TFTP_SERVER_DIR} ]; then
	echo "copy abort due to var TFTP_SERVER_DIR = null"
	exit 0
fi

echo "cp $APP_TAR_NAME ${TFTP_SERVER_DIR}/${ITL_LPC3250_PREFIX}$APP_TAR_NAME"
cp $APP_TAR_NAME ${TFTP_SERVER_DIR}/${ITL_LPC3250_PREFIX}$APP_TAR_NAME

