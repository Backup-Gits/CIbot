#!/bin/bash
# Copyright 2020 Giovix92
#
# Licensed under the Giovix92 License, Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You can find a copy here: 
# https://github.com/Giovix92/CIbot/blob/master/LICENSE

export CI_PATH="/home/giovix92/CI"

source $CI_PATH/vars.sh
source $CI_PATH/tools.sh

# Recheck for POWEROFF
if [ "$SERVER" == "true" ]; then
  POWEROFF=false
  messagefive="WARNING: Poweroff mode not available when in server build mode! Ignoring."
fi

if [ "$SERVER" == "true" ]; then
  if [ "$var2" == "revenge10" ]; then
    WORKINGDIR="ros_10"
  elif [ "$var2" == "revenge9" ]; then
    WORKINGDIR=
    echo "ROS9 building on server is currently not possible. Aborting."
    exit
  elif [ "$var2" == "twrp" ]; then
    WORKINGDIR=
    echo "TWRP building on server is currently not possible. Aborting."
    exit
  fi
elif [ "$SERVER" == "false" ]; then
  cd $WORKINGDIR
fi

date=$(date +%Y%m%d)
starttime=$(date +%H%M)
jobs=$(nproc --all)

# VAR EXPORT
export DEVICE COMMONDIR KERNELDIR ARCH
export WORKINGDIR BUILDTYPE TYPE CLEAN NOSYNC VERBOSE ANDROIDVER VARIANT SERVER NOCCACHE POWEROFF
export message messagetwo messagethree messagefour messagefive messageseex messageseven
export date starttime jobs

# SANITY CHECK
if [ "$WORKINGDIR" == "" ] || [ "$BUILDTYPE" == "" ] || [ "$WORKNAME" == "" ] || [ "$VARIANT" == "" ] || [ "$DEVICE" == "" ]; then
  echoo "VARS MISSING. CHECK VARS." "WORKINGDIR: $WORKINGDIR" "BUILDTYPE: $BUILDTYPE" "VARIANT: $VARIANT" "DEVICE: $DEVICE" "WORKNAME: $WORKNAME"
  exit
else
  echo "Vars are set, continuing"
fi

tgsay "Giovix92 CI Bot v$(echo $VERSION) started!" "$BUILDTYPE $ANDROIDVER build rolled at $date $starttime CEST!" "Device: $DEVICE, type: $TYPE" "Parameters used: $3 $4 $5 $6 $7"
if [ "$VERBOSE" == "true" ]; then
	tgsay "$message6" "Additional infos:" "$message" "$message2" "$message3" "$message4" "$message7" "$message5"
fi

if [ "$SERVER" == "false" ]; then
  if [ "$NOSYNC" == "false" ]; then
    syncsauce
  fi
fi

if [ "$TYPE" == "RECOVERY" ]; then
  echoo "Type: RECOVERY" "Set ALLOW_MISSING_DEPENDENCIES to true"
  export ALLOW_MISSING_DEPENDENCIES=true
fi

if [ "$NOCCACHE" == "false" ]; then
	ccachevarserver="export USE_CCACHE=1 CCACHE_MAX_SIZE=35G &&"
  ccachevar="export USE_CCACHE=1 CCACHE_COMPRESS=1 CCACHE_MAX_SIZE=35G"
fi

if [ "$SERVER" == "false" ]; then
  ### START THE PARTY, NO SERVER ###
  localbuild
  if [ "$errcount" == "1" ]; then
    localbuild
  fi
else
  ### START THE PARTY, USING SERVER ###
  serverbuild
  if [ "$errcount" == "1" ]; then
    serverbuild
  fi
fi

# LAST ONE
if [ "$POWEROFF" == "true" ]; then
  if [ "$SERVER" == "true" ]; then
    echo "Can't turn off server! Ignoring poweroff function."
  else
    poweroff
  fi
fi
