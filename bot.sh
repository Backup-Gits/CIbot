#!/bin/bash
# SET MAIN VARIABLES
TELEGRAM_TOKEN=$SECRET_TOKEN
TELEGRAM_CHAT=$CHAT_ID
TELEGRAM="/home/giovix92/CI/tg/telegram"
IP=$SERVER_IP
USERNAME=$SERVER_USERNAME
PASSWORD=$SERVER_PASSWORD
VERSION="2.0"

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
	if [ "$POWEROFF" == "true" ]; then
		if [ "$SERVER" == "true" ]; then
			echo "Can't turn off server! Ignoring poweroff function."
		else
			poweroff
		fi
	fi
    exit
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
	grep -Fiq "failed" "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
}

kernelused() {
	cat $WORKINGDIR/kernel/$VENDOR/$KERNELDIR/arch/arm64/configs/*$(echo $DEVICE)* | grep -i "CONFIG_LOCALVERSION"
}

# VARIABLES
if [ "$1" == "" ]; then
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  echo "Please, provide an option, or type help."
  exit
elif [ "$1" == "help" ]; then
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  echo "Command usage: bot.sh device romtype [nosync] [clean] [takelogs] [server] [poweroff] [noccache]"
  echo "Goodbye!"
  exit
elif [ "$1" == "changelog" ]; then
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  cat ./changelog.txt
  echo "Goodbye!"
  exit
fi
for var in "$@"
do
  if [ -z "$DEVICE" ]; then
    if [ "$var" == "tissot" ]; then
      DEVICE="tissot"
      COMMONDIR="msm8953-common"
      KERNELDIR="msm8953"
      VENDOR="xiaomi"
      ARCH="arm64"
    fi
  fi
  if [ -z "$DEVICE" ]; then
    if [ "$var" == "lavender" ]; then
      DEVICE="lavender"
      VENDOR="xiaomi"
      COMMONDIR=
      KERNELDIR="lavender"
      ARCH="arm64"
    fi
  fi
  if [ -z "$TYPE" ]; then
    if [ "$var" == "twrp" ]; then
      WORKINGDIR="/media/giovix92/HDD/twrp"
      BUILDTYPE="TWRP"
      VARIANT="eng"
      WORKNAME="omni"
      ANDROIDVER="3.3"
      TYPE="RECOVERY"
    fi
  fi
  if [ -z "$TYPE" ]; then
    if [ "$var" == "revenge10" ]; then
      WORKINGDIR="/media/giovix92/HDD/RevengeOS10"
      BUILDTYPE="RevengeOS"
      VARIANT="userdebug"
      WORKNAME="revengeos"
      ANDROIDVER="Q"
      TYPE=ROM
    fi
  fi
  if [ -z "$TYPE" ]; then
    if [ "$var" == "revenge9" ]; then
      WORKINGDIR="/media/giovix92/HDD/RevengeOS"
      BUILDTYPE="RevengeOS"
      VARIANT="userdebug"
      WORKNAME="revengeos"
      ANDROIDVER="Pie"
      TYPE=ROM
    fi
  fi
  if [ "$var" == "nosync" ]; then
      NOSYNC=true
      message="Nosync option added! Skipping syncing."
  fi
  if [ "$var" == "clean" ]; then
    CLEAN=true
    messagetwo="Clean option provided! Making a clean build."
  fi
  if [ "$var" == "takelogs" ]; then
    TAKELOGS=true
    messagethree="Takelogs option provided! Running in logging mode."
  fi
  if [ "$var" == "server" ]; then
    SERVER=true
    messagefour="Server option provided! Using server as build machine."
  fi
  if [ "$var" == "noccache" ]; then
    NOCCACHE=true
    messageseex="Noccache option provided! Excluding ccache for this build."
  fi
  if [ "$var" == "poweroff" ]; then
    if [ "$SERVER" == "true" ]; then
      POWEROFF=false
      messagefive="WARNING: Poweroff mode not available when in server build mode! Ignoring."
    else
      POWEROFF=true
      messagefive="Poweroff option provided! Turning off laptop after work!"
    fi
  fi
done
# Recheck for poweroff
if [ "$SERVER" == "true" ]; then
  POWEROFF=false
  messagefive="WARNING: Poweroff mode not available when in server build mode! Ignoring."
else
  POWEROFF=true
  messagefive="Poweroff option provided! Turning off laptop after work!"
fi

date=$(date +%Y%m%d)
starttime=$(date +%H%M)
jobs=$(nproc --all)

if [ "$SERVER" == "true" ]; then
  if [ "$2" == "revenge10" ]; then
    WORKINGDIR="/home/revenger/ros_10"
  elif [ "$2" == "revenge9" ]; then
    WORKINGDIR=
    echo "ROS9 building on server is currently not possible. Aborting."
    exit
  elif [ "$2" == "twrp" ]; then
    WORKINGDIR=
    echo "TWRP building on server is currently not possible. Aborting."
    exit
  fi
elif [ "$SERVER" == "false" ]; then
  cd $WORKINGDIR
fi

# VAR EXPORT
export DEVICE COMMONDIR KERNELDIR ARCH
export WORKINGDIR BUILDTYPE TYPE CLEAN NOSYNC TAKELOGS ANDROIDVER VARIANT SERVER NOCCACHE POWEROFF
export message messagetwo messagethree messagefour messagefive messageseex
export date starttime jobs

# SANITY CHECK
if [ "$WORKINGDIR" == "" ] || [ "$BUILDTYPE" == "" ] || [ "$WORKNAME" == "" ] || [ "$VARIANT" == "" ] || [ "$DEVICE" == "" ]; then
  echoo "VARS MISSING. CHECK VARS." "WORKINGDIR: $WORKINGDIR" "BUILDTYPE: $BUILDTYPE" "VARIANT: $VARIANT" "DEVICE: $DEVICE" "WORKNAME: $WORKNAME"
  exit
else
  echo "Vars are set, continuing"
fi

tgsay "Giovix92 CI Bot v$(echo $VERSION) started!" "$BUILDTYPE $ANDROIDVER build rolled at $date $starttime CEST!" "Device: $DEVICE, type: $TYPE"
if [ "$TAKELOGS" == "true" ]; then
	tgsay "Takelogs option provided!" "Additional infos:" "$message" "$messagetwo" "$messagethree" "$messagefour" "$messagefive" "$messageseex"
fi

exit # DEBUG

if [ "$NOSYNC" == "false" ]; then
  syncsauce
fi

if [ "$TYPE" == "RECOVERY" ]; then
  echoo "Type: RECOVERY" "Set ALLOW_MISSING_DEPENDENCIES to true"
  export ALLOW_MISSING_DEPENDENCIES=true
fi

if [ "$NOCCACHE" == "false" ]; then
	ccachevar="export USE_CCACHE="1" CCACHE_COMPRESS="1" CCACHE_MAX_SIZE="35G""
fi

### START THE PARTY, NO SERVER ###
if [ "$SERVER" == "false" ]; then
  if [ "$NOCCACHE" == "false" ]; then
	$ccachevar
  fi
  . build/envsetup.sh

  # CHECK FOR LOGS
  if [ -f "log*.txt" ]; then
    rm log*.txt
  fi

  # CHECK CLEAN VAR
  if [ "$CLEAN" == true ]; then
    make clean || tgsay "ERROR: Cleaning out/ terminated prematurely."
    if [ "$TYPE" == "ROM" ]; then
      make clobber || tgsay "ERROR: Cleaning out/ terminated prematurely."
    fi
    . build/envsetup.sh
  fi

  # LUNCH PART
  lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" 2>&1 | tee "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! @Giovix92 sar check log." "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if [ "$TYPE" == "ROM" ]; then
    brunch $DEVICE -j$jobs 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! @Giovix92 sar check log." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  else
    lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && make O=out recoveryimage 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! @Giovix92 sar check log." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  fi
  tgsay "$BUILDTYPE $ANDROIDVER build finished successfully!"
  exit

### START THE PARTY, USING SERVER ###
elif [ "$SERVER" == "true" ]; then
  servercmd "$ccachevar && cd $WORKINGDIR && make clean && . build/envsetup.sh && lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && brunch $(echo $DEVICE)" 2>&1 | tee "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  if checkserverlog; then
    tgerr "ERROR: $BUILDTYPE $ANDROIDVER server build failed! @Giovix92 sar check log." "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
  else
    tgsay "$BUILDTYPE $ANDROIDVER server build finished successfully!"
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