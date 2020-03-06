#!/bin/bash
# Copyright 2020 Giovix92
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
VERSION="3.2.1"
TELEGRAM_CHAT_USER=$CHAT_ID_USR

# SET VARIABLES TO FALSE
NOSYNC="false"
CLEAN="false"
VERBOSE="false"
SERVER="false"
NOCCACHE="false"
POWEROFF="false"
RETRYONFAIL="false"
QUIET="false"
errcount=0 

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
  KERNELUSED="perf+"
  ;;
  lavender)
  DEVICE="lavender"
  VENDOR="xiaomi"
  COMMONDIR="sdm660-common"
  KERNELDIR="lavender"
  ARCH="arm64"
  var1="lavender"
  KERNELUSED="perf+"
  ;;
  tulip)
  DEVICE="tulip"
  VENDOR="xiaomi"
  KERNELDIR="sdm660"
  COMMONDIR="sdm660-common"
  ARCH="arm64"
  var1="tulip"
  KERNELUSED=
  ;;
  twrp)
  WORKINGDIR="/run/media/giovix92/HDD/twrp"
  BUILDTYPE="TWRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="3.3"
  TYPE="RECOVERY"
  var2="twrp"
  KERNELUSED="Prebuilt (perf+)"
  ;;
  shrp)
  WORKINGDIR="/run/media/giovix92/HDD/shrp"
  BUILDTYPE="SHRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="2.2"
  TYPE="RECOVERY"
  var2="twrp"
  KERNELUSED="Prebuilt (perf+)"
  ;;
  revenge10)
  WORKINGDIR="/run/media/giovix92/HDD/RevengeOS10"
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Q"
  TYPE="ROM"
  var2="revenge10"
  ;;
  revenge9)
  WORKINGDIR="/run/media/giovix92/HDD/RevengeOS9"
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Pie"
  TYPE="ROM"
  var2="revenge9"
  ;;
  descendant)
  WORKINGDIR="/run/media/giovix92/HDD/Descendant"
  BUILDTYPE="Descendant"
  VARIANT="userdebug"
  WORKNAME="descendant"
  ANDROIDVER="10"
  TYPE="ROM"
  var2="descendant"
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
  verbose)
  VERBOSE=true
  message6="Verbose option provided! Running in logging mode."
  ;;
  retryonfail)
  RETRYONFAIL=true
  message7="Retryonfail option provided! Retrying when failing."
  ;;
  quiet)
  QUIET=true
  message8="Quiet option provided! Shh."
  ;;
  help)
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  echo "Command usage: bot.sh device romtype [nosync] [clean] [verbose] [server] [poweroff] [noccache]"
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
