#!/bin/sh

TIMEOUT=14400

SLEEPTIME=`date +%s`

sudo rtcwake -m mem -s $TIMEOUT

WAKETIME=`date +%s`
if [ $(($WAKETIME - $SLEEPTIME)) -ge $TIMEOUT ]
then
  sudo s2disk
else
  echo "nobernate :("
fi
