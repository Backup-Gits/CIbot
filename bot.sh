#!/bin/bash
# Copyright 2020 Giovix92
#
# Licensed under the Giovix92 License, Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You can find a copy here:
# https://github.com/Giovix92/CIbot/blob/master/LICENSE

export CI_PATH=$(pwd)

source $CI_PATH/vars.sh
source $CI_PATH/tools.sh

# Recheck for POWEROFF
if [ "$SERVER" == "true" ]; then
  POWEROFF=false
  echo "WARNING: Poweroff mode not available when in server build mode! Ignoring."
fi

if [ "$SERVER" == "false" ]; then
  cd $WORKINGDIR
fi

# Set some useful infos
date=$(date +%Y%m%d)
starttime=$(date +%H%M)

# Just export 'em in order to not sh*t anything
export DEVICE COMMONDIR KERNELDIR ARCH
export WORKINGDIR BUILDTYPE TYPE CLEAN NOSYNC VERBOSE ANDROIDVER VARIANT SERVER NOCCACHE POWEROFF
export date starttime

# Sanity check
for variable in TELEGRAM_CHAT TELEGRAM_TOKEN IP USERNAME PASSWORD
do
  if [ "$variable" == "" ]; then
    echo "$variable is missing!!"
    error=1
  fi
done

if [ "$error" == "1" ]; then
  echo "Add ALL the required variables. Exiting."
  exit
else
  echo "Vars are set correctly, continuing!"
fi

for variables in NOSYNC CLEAN VERBOSE SERVER NOCCACHE POWEROFF RETRYONFAIL QUIET jobs
do
  if [ "$variable" == "" ]; then
    echo "Variable $variable is missing! Setting it as false."
    $variable=false
  fi
done

# Let's announce the party
tgsay "Giovix92 CI Bot v$(echo $VERSION) started!" "$BUILDTYPE $ANDROIDVER build rolled at $date $starttime CEST!" "Device: $DEVICE, type: $TYPE"


if [ "$SERVER" == "false" ] && [ "$NOSYNC" == "false" ]; then
  syncsauce
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
  # The party begins! No server though.
  localbuild
  if [ "$errcount" == "1" ]; then
    localbuild
  fi
elif [ "$SERVER" == "true" ]; then
  # The party begins! With server!
  serverbuild
  if [ "$errcount" == "1" ]; then
    serverbuild
  fi
fi

# Party ended, sad.
if [ "$POWEROFF" == "true" ]; then
  if [ "$SERVER" == "true" ]; then
    echo "Can't turn off server! Ignoring poweroff function."
  else
    poweroff
  fi
fi
