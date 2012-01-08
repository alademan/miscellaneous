#!/bin/sh

# Author: Tony Lademan
# Purpose:  Simple script to blink a keyboard LED when
#         screen blanks.
# Usage:  Run as a background task 
#         (ex. in your .xinitrc or other start up script)
# TODO:  Hibernate after screen has been blanked for
#        X amount of time?


#DPMS_STATUS=$(xset q | /bin/grep "DPMS is")
#if [ "$DPMS_STATUS" == "  DPMS is Disabled" ]
#then
#  xset +dpms
#fi

TIMEOUT=5

MACHINE=$(hostname)
FELDSPAR_ADDRESS=alademan.homeip.net
LED=c5 
#LOCK_APP=$(DISPLAY=:0 sflock)

if [ "$MACHINE" == "ophiuchus" ]
then
  LED=s5
  FELDSPAR_ADDRESS=feldspar
  #LOCK_APP=""
fi

MONITOR_STATUS=$(DISPLAY=:0 xset q | grep Monitor | grep On)
if [ "$MONITOR_STATUS" == "" ]
then
#  echo "Attempt lock"
#  if [ "$(pidof $LOCK_APP)" == "" ]
#  then
#    $LOCK_APP & 
#    echo "** pidof $($LOCK_APP) **"
#    echo "Lock the screen once, here. Never see again."
#  fi
  echo "Start Blink"
  if [ $(cat ~/.led_status) -eq 1 ]
  then
    if [ -n "$(wmctrl -l | grep ssh:feldspar)" ]
    then
      #ledcontrol set $LED blink 100 2000
      #ledcontrol anim loop C 100 c 50 C 100 c 2000
      #ledcontrol set n1 off
      echo "1 check hit"
      echo "0" > ~/.led_status
      ssh $FELDSPAR_ADDRESS "echo 'irc.aim.&chat */away -all idle' > .weechat/weechat_fifo_*"
    fi
  fi
else
  echo "Stop Blink"
  if [ $(cat ~/.led_status) -eq 0 ]
  then
    if [ -n "$(wmctrl -l | grep ssh:feldspar)" ]
    then
      #ledcontrol set $LED off
      #ledcontrol set $LED normal
      #ledcontrol anim
      #ledcontrol set n1 on
      echo "0 check hit"
      echo "1" > ~/.led_status
      ssh $FELDSPAR_ADDRESS "echo 'irc.aim.&chat */away -all' > .weechat/weechat_fifo_*"
    fi
  fi
  TIMEOUT=5
fi

echo "$MONITOR_STATUS"
echo "l=$LOCK_IS_LOCKED t=$TIMEOUT"
echo -en "\n\n"
sleep $TIMEOUT

$0 &
