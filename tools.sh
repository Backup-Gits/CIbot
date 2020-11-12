#!/bin/bash
# Copyright 2020 Giovix92
#
# Licensed under the Giovix92 License, Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You can find a copy here:
# https://github.com/Giovix92/CIbot/blob/master/LICENSE

export CI_PATH=$(pwd)
errcount=0

# Source vars
source $CI_PATH/vars.sh

# Export Telegram bin
export TELEGRAM="${CI_PATH}/tg/telegram"

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
  if [ "$errcount" == "2" ] && [ "$RETRYONFAIL" == "true" ] || [ "$RETRYONFAIL" == "false" ]; then
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
  repo sync --force-remove-dirty -d -c -v --no-clone-bundle --no-tags || tgerr "ERROR: Syncing repo dir terminated prematurely."
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

buildf() {
  if [ "$1" == "lunch" ]; then
    lunch $(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT) 2>&1 | tee "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed!" "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  elif [ "$1" == "source" ]; then
    source build/envsetup.sh
  elif [ "$1" == "build" ]; then
    if [ "$ANDROIDVER" == "R" ] || [ "$ANDROIDVER" == "P" ]; then
      # On P/R we still use mka
      mka $(echo $MAKECMD) 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    elif [ "$ANDROIDVER" == "Q" ]; then
      # Q is "special" rofl
      brunch $(eco $DEVICE) 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    fi
  elif [ "$1" == "clean" ]; then
    make clean
  fi
}

localbuild() {
  # Check if we shall use ccache or not
  if [ "$NOCCACHE" == "false" ]; then
    $ccachevar
  fi

  # Let's begin!
  buildf source

  # Check for leftover logs
  if [ -f "log*" ]; then
    rm -r log*.txt
  fi

  # Clean if set
  if [ "$CLEAN" == "true" ]; then
    if [ "$ANDROIDVER" == "R" ]; then
      # We need to lunch on R before cleaning
      buildf lunch
      buildf clean || tgsay "ERROR: Cleaning out/ terminated prematurely."
    else
      # On P/Q just clean it all
      buildf clean || tgsay "ERROR: Cleaning out/ terminated prematurely."
    fi
    # Re-source everything, just to be ok
    buildf source
  fi

  # Lunch everything
  buildf lunch

  # Build everything
  buildf build

  if isCompleted; then
    tgfinish
  fi
}

serverbuild() {
  if [ "$CLEAN" == "true" ]; then
    servercmd "cd $(echo $REMOTEDIR) && make clean"
  fi
  if [ "$NOSYNC" == "false" ]; then
    servercmd "cd $(echo $REMOTEDIR) && repo sync -c -f --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune"
  fi
  servercmd "cd $(echo $REMOTEDIR) && source build/envsetup.sh && lunch $(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT) && mka $(echo $MAKECMD)" 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if isCompleted; then
    tgfinish
  else
    tgerr "ERROR: $BUILDTYPE $ANDROIDVER server build failed!" "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  fi
}
