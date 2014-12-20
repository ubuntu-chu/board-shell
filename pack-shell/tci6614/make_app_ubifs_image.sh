#!/bin/sh

#350MiB  for 512MiB nandflash
APP_UBI_IMAGE_NAME=app-512MiB.img
APP_VOL_SIZE=367001600
./_make_app_ubifs_image.sh $APP_UBI_IMAGE_NAME $APP_VOL_SIZE

#20MiB   for 128MiB nandflash
APP_UBI_IMAGE_NAME=app-128MiB.img
APP_VOL_SIZE=20971520
./_make_app_ubifs_image.sh $APP_UBI_IMAGE_NAME $APP_VOL_SIZE

#120MiB  for 256MiB nandflash
APP_UBI_IMAGE_NAME=app-256MiB.img
APP_VOL_SIZE=125829120
./_make_app_ubifs_image.sh $APP_UBI_IMAGE_NAME $APP_VOL_SIZE



