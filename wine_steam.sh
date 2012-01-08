#!/bin/sh
#
# Who: Tony Lademan
# What: Launches Steam from chosen wine prefix.
#       Assumes that we want to launch Steam and Steam only.
# Why: Sometimes a game or other program needs a fresh wine environment
#      to function properly.
#
# TODO: Allow for an unobtrusive option to launch winecfg with chosen prefix.

# Define the base path for wine installations.
WINELOCATION=~/.wine

get_wine_prefixes()
{
  # Let's find all of the wine prefixes the user has.
  # i.e.
  #   ~/.wine
  #   ~/.wine_greed_corp
  #   ~/.wine_some_other_game
  #   ~/.wine_office_product_X

  unset PREFIXES
  for i in $(ls -d $WINELOCATION*)
  do
    PREFIXES+=("FALSE")
    PREFIXES+=("$i")
  done
}

zenity_chooser()
{
  # If there's only one ~/.wine* folder, then we will auto launch
  # steam from that directory.  Otherwise, if there's more than one,
  # we use zenity to let us easily choose which one we want to use.
  #
  # Hopefully they're descriptively named.

  echo ${PREFIXES[@]}
  if [[ ${#PREFIXES[@]} -eq 0 ]]
  then
    zenity --error --text="No wine install found, if this is in error, please update the script to look in the right place."
    exit
  fi
  if [[ ${#PREFIXES[@]} -eq 2 ]]
  then
    WINEDIR=${PREFIXES[1]}
    echo $WINEDIR
    wine_launch
  else
    WINEDIR=$(zenity --list --text "Choose wine install:" \
    --radiolist --column "" --column "dir" "${PREFIXES[@]}") 
    echo $WINEDIR
    if [[ "$WINEDIR" == "" ]]
    then
      zenity --error --text="Please choose the appropriate wine installation"
    else
      wine_launch
    fi
  fi
}

wine_launch()
{
  # For some reason, the .wine_greed_corps prefix is a 64bit install
  # while the .wine prefix is only 32bit.  So, here we check to see
  # which we're running and then we choose the appropriate Program Files
  # directory.
  #
  # I imagine this could be done with some sort of array and for loop
  # business should multiple prefixes end up doing this kind of thing.

  PROGFILES="Program Files"
  if [[ "$WINEDIR" == "/home/satoshi/.wine_greed_corps" ]] || [[ "$WINEDIR" == "/home/satoshi/.wine_terraria" ]] || [[ "$WINEDIR" == "/home/satoshi/.wine_basic_steam" ]] || [[ "$WINEDIR" == "/home/satoshi/.wine_aquaria" ]]
  then
    PROGFILES="Program Files (x86)"
  fi

  # Launch Steam, finally!
  cd "$WINEDIR/drive_c/$PROGFILES/Steam/"
  if [[ "$(hostname)" == "ophiuchus" ]]
  then
    comp -s
  fi
  WINEPREFIX=$WINEDIR WINEDEBUG=-all nice -n 19 wine Steam.exe
  if [[ "$(hostname)" == "ophiuchus" ]]
  then
    comp
  fi
}

# Start the whole process
get_wine_prefixes
zenity_chooser
