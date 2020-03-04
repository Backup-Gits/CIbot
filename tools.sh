#!/bin/bash
# Copyright 2020 Giovix92
#
# Licensed under the Giovix92 License, Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You can find a copy here: 
# https://github.com/Giovix92/CIbot/blob/master/LICENSE

export CI_PATH="/home/giovix92/CI"

source $CI_PATH/vars.sh

# FUNCTIONS
tgsay() {
  if [ "$QUIET" == "false" ]; then
    $TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT -H \
      "$(
		  for POST in "${@}"; do
		  	echo "${POST}"
		  done
      )"
  fi
}

tgerr() {
  if [ "$QUIET" == "false" ]; then
	  if [ "$VERBOSE" == "true" ]; then
	    tgsay "$1" "Percentage: $(cat logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt | grep -Eo '[0-9]+%' | awk 'END{print}')"
      $TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT_USER -f "$2" "$1"
	  elif [ "$VERBOSE" == "false" ]; then
	    $TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT "$1"
	  fi
  fi
  ((errcount++))
	if [ "$POWEROFF" == "true" ]; then
		if [ "$SERVER" == "true" ]; then
			echo "Can't turn off server! Shutting down PC in 30 seconds."
      sleep 30
		fi
    poweroff
	fi
  if [ "$errcount" == "2" ] && [ "$RETRYONFAIL" == "true" ]; then
    exit
  elif [ "$RETRYONFAIL" == "false" ]; then
    exit
  fi
}

tgfinish() {
  if [ "$QUIET" == "false" ]; then
    finishmsg=$(cat logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt | awk 'END{print}')
    tgsay "$BUILDTYPE $ANDROIDVER build for $DEVICE finished successfully!" "$finishmsg"
  fi
}

syncsauce() {
  repo sync --force-sync --force-remove-dirty -d -c -v --no-clone-bundle --no-tags || tgsay "ERROR: Syncing repo dir terminated prematurely."
}

echoo() {
	echo "$(
		for MESSAGE in "${@}"; do
			echo "${MESSAGE}"
		done
    )"
}

servercmd() {
	if [ "$SERVER" == "true" ]; then
	  sshpass -p "$(echo $PASSWORD)" ssh -o StrictHostKeyChecking=no $(echo $USERNAME)@$(echo $IP) "$1"
  fi
}

isCompleted() {
  if cat logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt | grep -Fiq "build completed"; then
    return 0
  else
    return 1
  fi
}

localbuild() {
  if [ "$NOCCACHE" == "false" ]; then
  $ccachevar
  fi
  . build/envsetup.sh

  # CHECK FOR LOGS
  if [ -f "$(PWD)/log*" ]; then
    rm log*
  fi

  # CHECK CLEAN VAR
  if [ "$CLEAN" == "true" ]; then
    make clean || tgsay "ERROR: Cleaning out/ terminated prematurely."
    if [ "$TYPE" == "ROM" ]; then
      make clobber || tgsay "ERROR: Cleaning out/ terminated prematurely."
    fi
    . build/envsetup.sh
  fi

  # LUNCH PART
  lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" 2>&1 | tee "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed!" "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if [ "$TYPE" == "ROM" ]; then
    if [ "$ANDROIDVER" == "Q" ]; then
      brunch $DEVICE 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    else
      lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && mka bacon 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    fi
  else
    lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && make O=out recoveryimage 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    tgfinish
  fi
}

serverbuild() {
  if [ "$CLEAN" == "true" ]; then
    servercmd "cd $(echo $WORKINGDIR) && make clean"
  fi
  if [ "$NOSYNC" == "false" ]; then
    servercmd "cd $(echo $WORKINGDIR) && repo sync -c -f --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune"
  fi
  servercmd "build $(echo $DEVICE)" 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if isCompleted; then
    tgfinish
  else
    tgerr "ERROR: $BUILDTYPE $ANDROIDVER server build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  fi
} 
