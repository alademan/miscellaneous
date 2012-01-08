#!/bin/sh

# Author: Tony Lademan <tony@alademan.com>
# Purpose:  Simple script to do something when DPMS triggers.
#
# Usage:  Run as a background task 
#         (ex. in your .xinitrc or other start up script)
#
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

if [ "$MACHINE" == "ophiuchus" ]
then
  LED=s5
  FELDSPAR_ADDRESS=feldspar
fi

DPMS_STATUS=$(DISPLAY=:0 xset q | grep DPMS | grep Disabled)
if [ "$DPMS_STATUS" == "" ]
then
  MONITOR_STATUS=$(DISPLAY=:0 xset q | grep Monitor | grep On)
  if [ "$MONITOR_STATUS" == "" ]
  then
    if [ $(cat ~/.led_status) -eq 1 ]
    then
      if [ -n "$(wmctrl -l | grep ssh:feldspar)" ]
      then
        echo "0" > ~/.led_status
        ssh $FELDSPAR_ADDRESS "echo 'irc.aim.&chat */away -all idle' > .weechat/weechat_fifo_*"
      fi
    fi
  else
    if [ $(cat ~/.led_status) -eq 0 ]
    then
      if [ -n "$(wmctrl -l | grep ssh:feldspar)" ]
      then
        echo "1" > ~/.led_status
        ssh $FELDSPAR_ADDRESS "echo 'irc.aim.&chat */away -all' > .weechat/weechat_fifo_*"
      fi
    fi
    TIMEOUT=5
  fi
fi

sleep $TIMEOUT

$0 &
