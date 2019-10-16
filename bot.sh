#!/bin/bash
# SET MAIN VARIABLES
TELEGRAM_TOKEN=$SECRET_TOKEN
TELEGRAM_CHAT=$CHAT_ID
TELEGRAM="/home/giovix92/CI/tg/tgram"

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
	$TELEGRAM -t $TELEGRAM_TOKEN -c $TELEGRAM_CHAT -f "$2" "$1"
  exit 1
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

echoo () {
	echo "$(
		for MESSAGE in "${@}"; do
			echo "${MESSAGE}"
		done
    )"
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
  echo "Giovix92 CI Bot v1.2"
  echo "Command usage: bot.sh device romtype [nosync] [clean] [takelogs]"
  echo "Goodbye!"
  exit
elif [ "$1" == "changelog" ]; then
  echo "Giovix92 CI Bot 1.2.2"
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
if [ "$3" == "nosync" ] || [ "$4" == "nosync" ] || [ "$5" == "nosync" ]; then
  NOSYNC=true
  message="Nosync option added! Skipping syncing."
else
  NOSYNC=false
  message="No "nosync" option provided! Syncing."
fi
if [ "$3" == "clean" ] || [ "$4" == "clean" ] || [ "$5" == "clean" ]; then
  CLEAN=true
  messagetwo="Clean option provided! Making a clean build."
else
  CLEAN=false
  messagetwo="No "clean" option provided! Making a dirty build."
fi
if [ "$3" == "takelogs" ] || [ "$4" == "takelogs" ] || [ "$5" == "takelogs" ]; then
  TAKELOGS=true
  messagethree="Takelogs option provided! Running in logging mode."
else
  TAKELOGS=false
  messagethree="No "takelogs" option provided! Running in silent mode."
fi

export WORKINGDIR BUILDTYPE TYPE CLEAN NOSYNC TAKELOGS ANDROIDVER VARIANT
export message messagetwo messagethree

date=$(date +%Y%m%d)
starttime=$(date +%H%M)
jobs=$(nproc --all)

tgsay "$BUILDTYPE $ANDROIDVER build rolled at $date $starttime CEST!" "Device: $DEVICE, type: $TYPE" "Additional infos:" "$message" "$messagetwo" "$messagethree"
cd $WORKINGDIR

if [ "$NOSYNC" == "false" ]; then
  syncsauce
fi

if [ "$TYPE" == "RECOVERY" ]; then
  echoo "Type: RECOVERY" "Set ALLOW_MISSING_DEPENDENCIES to true"
  export ALLOW_MISSING_DEPENDENCIES=true
fi

# SANITY CHECK
if [ "$WORKINGDIR" == "" ] || [ "$BUILDTYPE" == "" ] || [ "$WORKNAME" == "" ] || [ "$VARIANT" == "" ] || [ "$DEVICE" == "" ]; then
  echoo "VARS MISSING. CHECK VARS." "WORKINGDIR: $WORKINGDIR" "BUILDTYPE: $BUILDTYPE" "VARIANT: $VARIANT" "DEVICE: $DEVICE" "WORKNAME: $WORKNAME"
  exit 1
else
  echo "Vars are set, continuing"
fi

# START THE PARTY
. build/envsetup.sh

# CHECK FOR LOGS
if [ -f "./log*.txt" ]; then
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
lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" 2>&1 | tee "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! Check log." "loglunch-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
if [ "$TYPE" == "ROM" ]; then
  brunch $DEVICE -j$jobs 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! Check log." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
else
  lunch "$(echo $WORKNAME)_$(echo $DEVICE)-$(echo $VARIANT)" && make O=out recoveryimage 2>&1 | tee "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt" || tgerr "ERROR: $BUILDTYPE $ANDROIDVER lunch failed! Check log." "logbuild-$BUILDTYPE-$ANDROIDVER-$date-$starttime.txt"
fi
tgsay "$BUILDTYPE $ANDROIDVER build finished successfully!"
exit