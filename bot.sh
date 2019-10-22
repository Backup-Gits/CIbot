#!/bin/bash
# SET MAIN VARIABLES
TELEGRAM_TOKEN=$SECRET_TOKEN
TELEGRAM_CHAT=$CHAT_ID
TELEGRAM="/home/giovix92/CI/tg/telegram"
IP=$SERVER_IP
USERNAME=$SERVER_USERNAME
PASSWORD=$SERVER_PASSWORD
VERSION="1.6"

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
  cd device/xiaomi/$1/
  git pull
  cd $WORKINGDIR
  if [ $COMMONDIR ]; then
    cd device/xiaomi/$COMMONDIR/
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
	if [ grep -Fiq "#### failed" "logserver-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" ]; then
		ERROR=true
	else
		ERROR=false
	fi
}

# VARIABLES
if [ "$1" == "tissot" ]; then
  DEVICE=tissot
  COMMONDIR=msm8953-common
  KERNELDIR=msm8953
  ARCH=arm64
elif [ "$1" == "lavender" ]; then
  DEVICE=lavender
  COMMONDIR=none
  KERNELDIR=lavender
  ARCH=arm64
elif [ "$1" == "" ]; then
  echo "Please, provide an option, or type help."
  exit
elif [ "$1" == "help" ]; then
  echo "Giovix92 CI Bot $(echo VERSION)"
  echo "Command usage: bot.sh device romtype [nosync] [clean] [takelogs] [server] [poweroff] [noccache]"
  echo "Goodbye!"
  exit
elif [ "$1" == "changelog" ]; then
  echo "Giovix92 CI Bot $(echo VERSION)"
  cat ./changelog.txt
  echo "Goodbye!"
  exit
fi
export DEVICE COMMONDIR KERNELDIR ARCH 
if [ "$2" == "twrp" ]; then
  WORKINGDIR="/media/giovix92/HDD/twrp"
  BUILDTYPE="TWRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="3.3"
  TYPE="RECOVERY"
elif [ "$2" == "revenge10" ]; then
  WORKINGDIR="/media/giovix92/HDD/RevengeOS10"
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Q"
  TYPE=ROM
elif [ "$2" == "revenge9" ]; then
  WORKINGDIR="/media/giovix92/HDD/RevengeOS"
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Q"
  TYPE=ROM
fi
if [ "$3" == "nosync" ] || [ "$4" == "nosync" ] || [ "$5" == "nosync" ] || [ "$6" == "nosync" ] || [ "$7" == "nosync" ] || [ "$8" == "nosync" ]; then
  NOSYNC=true
  message="Nosync option added! Skipping syncing."
else
  NOSYNC=false
  message="No "nosync" option provided! Syncing."
fi
if [ "$3" == "clean" ] || [ "$4" == "clean" ] || [ "$5" == "clean" ] || [ "$6" == "clean" ] || [ "$7" == "clean" ] || [ "$8" == "clean" ]; then
  CLEAN=true
  messagetwo="Clean option provided! Making a clean build."
else
  CLEAN=false
  messagetwo="No "clean" option provided! Making a dirty build."
fi
if [ "$3" == "takelogs" ] || [ "$4" == "takelogs" ] || [ "$5" == "takelogs" ] || [ "$6" == "takelogs" ] || [ "$7" == "takelogs" ] || [ "$8" == "takelogs" ]; then
  TAKELOGS=true
  messagethree="Takelogs option provided! Running in logging mode."
else
  TAKELOGS=false
  messagethree="No "takelogs" option provided! Running in silent mode."
fi
if [ "$3" == "server" ] || [ "$4" == "server" ] || [ "$5" == "server" ] || [ "$6" == "server" ] || [ "$7" == "server" ] || [ "$8" == "server" ]; then
  SERVER=true
  messagefour="Server option provided! Using server as build machine."
else
  SERVER=false
  messagefour="No "server" option provided. Using laptop as build machine."
fi
if [ "$3" == "noccache" ] || [ "$4" == "noccache" ] || [ "$5" == "noccache" ] || [ "$6" == "noccache" ] || [ "$7" == "noccache" ] || [ "$8" == "noccache" ]; then
  NOCCACHE=true
  messageseex="Noccache option provided! Excluding ccache for this build."
else
  NOCCACHE=false
  messageseex="No "noccache" option provided. Speeding up!"
fi

# INITIAL VAR EXPORT
export WORKINGDIR BUILDTYPE TYPE CLEAN NOSYNC TAKELOGS ANDROIDVER VARIANT SERVER NOCCACHE
export message messagetwo messagethree messagefour messageseex

if [ "$3" == "poweroff" ] || [ "$4" == "poweroff" ] || [ "$5" == "poweroff" ] || [ "$6" == "poweroff" ] || [ "$7" == "poweroff" ] || [ "$8" == "poweroff" ]; then
  if [ "$SERVER" == "true" ]; then
  	POWEROFF=false
  	messagefive="WARNING: Poweroff mode not available when in server build mode! Ignoring."
  else
    POWEROFF=true
    messagefive="Poweroff option provided! Turning off laptop after work!"
  fi
else
  POWEROFF=false
  messagefive="No "poweroff" option provided. Laptop will stay on."
fi

date=$(date +%Y%m%d)
starttime=$(date +%H%M)
jobs=$(nproc --all)

# FINAL VAR EXPORT
export POWEROFF messagefive date starttime jobs

tgsay "Giovix92 CI Bot $(echo VERSION) started!" "$BUILDTYPE $ANDROIDVER build rolled at $date $starttime CEST!" "Device: $DEVICE, type: $TYPE" 
if [ "$TAKELOGS" == "true" ]; then
	tgsay "Verbose option provided!" "Additional infos:" "$message" "$messagetwo" "$messagethree" "$messagefour" "$messagefive" "$messageseex"
fi

if [ "$SERVER" == "true" ]; then
  if [ "$2" == "revenge10" ]; then
    WORKINGDIR="ros_10"
  elif [ "$2" == "revenge9" ]; then
    WORKINGDIR=
  elif [ "$2" == "twrp" ]; then
    WORKINGDIR=
    echo "TWRP building on server is currently not possible. Aborting."
    exit
  fi
elif [ "$SERVER" == "false" ]; then
  cd $WORKINGDIR
fi

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

# SANITY CHECK
if [ "$WORKINGDIR" == "" ] || [ "$BUILDTYPE" == "" ] || [ "$WORKNAME" == "" ] || [ "$VARIANT" == "" ] || [ "$DEVICE" == "" ]; then
  echoo "VARS MISSING. CHECK VARS." "WORKINGDIR: $WORKINGDIR" "BUILDTYPE: $BUILDTYPE" "VARIANT: $VARIANT" "DEVICE: $DEVICE" "WORKNAME: $WORKNAME"
  exit
else
  echo "Vars are set, continuing"
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
  checkserverlog
  if [  "$ERROR" == "true" ]; then
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