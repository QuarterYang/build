#!/bin/sh

LOG_FILE=/tmp/kickpi.log

depmod

dmesg -n 1

echo " kickpi.sh run finish !" >> $LOG_FILE
