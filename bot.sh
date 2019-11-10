#!/bin/bash
# Copyright 2019 Giovix92
#
# Licensed under the Giovix92 License, Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You can find a copy here: 
# https://github.com/Giovix92/CIbot/blob/master/LICENSE

# SET MAIN VARIABLES
TELEGRAM_TOKEN=$SECRET_TOKEN
TELEGRAM_CHAT=$CHAT_ID
TELEGRAM="/home/giovix92/CI/tg/telegram"
IP=$SERVER_IP
USERNAME=$SERVER_USERNAME
PASSWORD=$SERVER_PASSWORD
VERSION="2.3"

# SET VARIABLES TO FALSE
NOSYNC="false"
CLEAN="false"
TAKELOGS="false"
SERVER="false"
NOCCACHE="false"
POWEROFF="false"
RETRYONFAIL="false"
errcount=0

# FUNCTIONS
tgsay() {
  $TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

tgerr () {
	if [ "$TAKELOGS" == "true" ]; then
	  $TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT -f "$2" "$1"
	elif [ "$TAKELOGS" == "false" ]; then
	  $TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT "$1"
	fi
  ((errcount++))
	if [ "$POWEROFF" == "true" ]; then
		if [ "$SERVER" == "true" ]; then
			echo "Can't turn off server! Ignoring poweroff function."
		else
			poweroff
		fi
	fi
  if [ "$errcount" == "2" ] && [ "$RETRYONFAIL" == "true" ]; then
    exit
  fi
}

syncsauce() {
  repo sync -c -f --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune || tgsay "ERROR: Syncing repo dir terminated prematurely."
}

syncall() {
  repo sync -c -f --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune || tgsay "ERROR: Syncing repo dir terminated prematurely."
  cd device/$VENDOR/$DEVICE/
  git pull
  cd $WORKINGDIR
  if [ -v "$COMMONDIR" ]; then
    cd device/$VENDOR/$COMMONDIR/
    git pull
  fi
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

checkserverlog() {
	grep -Fiq "build completed" "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
}

kernelused() {
  kernelusedcmd=". $WORKINGDIR/kernel/$VENDOR/$KERNELDIR/kernelver.sh"
  if [ "$SERVER" == "false" ]; then
	cd kernel/$VENDOR/$KERNELDIR/arch/arm64/configs/
    export $(grep "CONFIG_LOCALVERSION=" *$DEVICE_defconfig | cut -d\   -f2)
    KERNELTYPE=$(echo $CONFIG_LOCALVERSION)
  fi
}

localbuild() {
  if [ "$NOCCACHE" == "false" ]; then
  $ccachevar
  fi
  . build/envsetup.sh

  # CHECK FOR LOGS
  if [ -f "$PWD/log*" ]; then
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
  lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" 2>&1 | tee "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! @Giovix92 sar check log." "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if [ "$TYPE" == "ROM" ]; then
    brunch $DEVICE -j$jobs 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || if [ "$errcount" == "1" ]; then tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed! @Giovix92 sar check log. Retrying for the last time." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"; else tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed! @Giovix92 sar check log. Something is REALLY WRONG." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"; fi
  else
    lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && make O=out recoveryimage 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || if [ "$errcount" == "1" ]; then tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed! @Giovix92 sar check log. Retrying for the last time." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"; else tgerr "ERROR: $BUILDTYPE $ANDROIDVER build failed! @Giovix92 sar check log. Something is REALLY WRONG." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"; fi
  fi
  tgsay "$BUILDTYPE $ANDROIDVER build finished successfully!"
}

serverbuild() {
  servercmd "$ccachevarserver cd $WORKINGDIR && make clean && . build/envsetup.sh && lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && brunch $(echo $DEVICE)" 2>&1 | tee "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if checkserverlog; then
    tgsay "$BUILDTYPE $ANDROIDVER server build finished successfully!"
  else
    if [ "$errcount" == "1" ]; then
      tgerr "ERROR: $BUILDTYPE $ANDROIDVER server build failed! @Giovix92 sar check log. Retrying for the last time." "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    elif [ "$errcount" == "2" ]; then
      tgerr "ERROR: $BUILDTYPE $ANDROIDVER server build failed! @Giovix92 sar check log. Something is REALLY WRONG." "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
    fi
  fi
}

# VARIABLES
for var in "$@"
do
case $var in
  tissot)
  DEVICE="tissot"
  COMMONDIR="msm8953-common"
  KERNELDIR="msm8953"
  VENDOR="xiaomi"
  ARCH="arm64"
  var1="tissot"
  ;;
  lavender)
  DEVICE="lavender"
  VENDOR="xiaomi"
  COMMONDIR=
  KERNELDIR="lavender"
  ARCH="arm64"
  var1="lavender"
  ;;
  twrp)
  WORKINGDIR="/media/giovix92/HDD/twrp"
  BUILDTYPE="TWRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="3.3"
  TYPE="RECOVERY"
  var2="twrp"
  ;;
  shrp)
  WORKINGDIR="/media/giovix92/HDD/shrp"
  BUILDTYPE="SHRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="2.1"
  TYPE="RECOVERY"
  var2="twrp"
  ;;
  revenge10)
  WORKINGDIR="/media/giovix92/HDD/RevengeOS10"
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Q"
  TYPE="ROM"
  var2="revenge10"
  ;;
  revenge9)
  WORKINGDIR="/media/giovix92/HDD/RevengeOS"
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Pie"
  TYPE="ROM"
  var2="revenge9"
  ;;
  nosync)
  NOSYNC=true
  message="Nosync option added! Skipping syncing."
  ;;
  clean)
  CLEAN=true
  message2="Clean option provided! Making a clean build."
  ;;
  server)
  SERVER=true
  message3="Server option provided! Using server as build machine."
  ;;
  noccache)
  NOCCACHE=true
  message4="Noccache option provided! Excluding ccache for this build."
  ;;
  poweroff)
  POWEROFF=true
  message5="Poweroff option provided! Turning off laptop after work!"
  ;;
  takelogs)
  TAKELOGS=true
  message6="Takelogs option provided! Running in logging mode."
  ;;
  retryonfail)
  RETRYONFAIL=true
  message7="Retryonfail option provided! Retrying when failing."
  ;;
  help)
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  echo "Command usage: bot.sh device romtype [nosync] [clean] [takelogs] [server] [poweroff] [noccache]"
  echo "Goodbye!"
  exit
  ;;
  changelog)
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  cat ./changelog.txt
  echo "Goodbye!"
  exit
  ;;
  ""|*)
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  echo "Please, provide a valid option, or type help."
  exit
  ;;
esac
done

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
export WORKINGDIR BUILDTYPE TYPE CLEAN NOSYNC TAKELOGS ANDROIDVER VARIANT SERVER NOCCACHE POWEROFF
export message messagetwo messagethree messagefour messagefive messageseex messageseven
export date starttime jobs

# SANITY CHECK
if [ "$WORKINGDIR" == "" ] || [ "$BUILDTYPE" == "" ] || [ "$WORKNAME" == "" ] || [ "$VARIANT" == "" ] || [ "$DEVICE" == "" ]; then
  echoo "VARS MISSING. CHECK VARS." "WORKINGDIR: $WORKINGDIR" "BUILDTYPE: $BUILDTYPE" "VARIANT: $VARIANT" "DEVICE: $DEVICE" "WORKNAME: $WORKNAME"
  exit
else
  echo "Vars are set, continuing"
fi

# Kernel check path
if [ "$TYPE" == "ROM" ]; then
  kernelused
  if [ "$SERVER" == "true" ]; then
    KERNELTYPEN=$(servercmd "$kernelusedcmd")
    KERNELTYPE=$KERNELTYPEN
  fi
elif [ "$TYPE" == "RECOVERY" ]; then
	KERNELTYPE="Prebuilt"
fi

tgsay "Giovix92 CI Bot v$(echo $VERSION) started!" "$BUILDTYPE $ANDROIDVER build rolled at $date $starttime CEST!" "Device: $DEVICE, type: $TYPE" "Kernel: $KERNELTYPE"
if [ "$TAKELOGS" == "true" ]; then
	tgsay "Takelogs option provided!" "Additional infos:" "$message" "$message2" "$message3" "$message4" "$message7" "$message6" "$message5"
fi

if [ "$NOSYNC" == "false" ]; then
  syncall
fi

if [ "$TYPE" == "RECOVERY" ]; then
  echoo "Type: RECOVERY" "Set ALLOW_MISSING_DEPENDENCIES to true"
  export ALLOW_MISSING_DEPENDENCIES=true
fi

if [ "$NOCCACHE" == "false" ]; then
	ccachevarserver="export USE_CCACHE="1" CCACHE_COMPRESS="1" CCACHE_MAX_SIZE="35G" &&"
  ccachevar="export USE_CCACHE="1" CCACHE_COMPRESS="1" CCACHE_MAX_SIZE="35G""
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
