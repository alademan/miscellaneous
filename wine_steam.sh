#!/bin/sh
#
# Author:  Tony Lademan <tony@alademan.com>
#
# Purpose: Launches Steam from chosen wine prefix.
#          Assumes that we want to launch Steam and Steam only.
#
# Why: Sometimes a game or other program needs a fresh wine environment
#      to function properly.
#
# Dependencies: zenity
#
# TODO: CLEAN THIS CODE UP.
#       Moving to launch steam only from ~/Steam/Steam.exe no matter 
#       what the prefix is.  This makes Steam unified and accessible.

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
    title=$(echo $i | awk -F"/" '{ print $4 }')
    if [[ "$i" == "/home/satoshi/.wine" ]]
    then
      PREFIXES+=("TRUE")
      PREFIXES+=("$title")
    else
      PREFIXES+=("FALSE")
      PREFIXES+=("$title")
    fi
  done
}

zenity_chooser()
{
  # All Steams are automatically launched from ~/Steam.  This allows for the steam config to be the same across bottles and so that all bottles have the same access to games.  The only major changes per bottles are the other installed software and registry settings.  Those will still reside appropriate in the correct bottle.

  if [[ ${#PREFIXES[@]} -eq 0 ]]
  then
    zenity --error --text="No wine install found, if this is in error, please update the script to look in the right place."
    exit
  fi
  if [[ ${#PREFIXES[@]} -eq 2 ]]
  then
    WINEDIR=${PREFIXES[1]}
    wine_launch
  else
    WINEDIR=$(zenity --list --text "Choose wine install:" \
    --radiolist --column "" --column "dir" "${PREFIXES[@]}") 
    if [[ "$WINEDIR" = "" ]]
    then
      echo "Exiting.."
    else
      wine_launch
    fi
  fi
}

wine_launch()
{
  cd /home/satoshi/Steam/
  WINEPREFIX=~/$WINEDIR WINEDEBUG=-all nice -n 19 wine Steam.exe
}

# Start the whole process
get_wine_prefixes
zenity_chooser
