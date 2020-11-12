#!/bin/bash
# Copyright 2020 Giovix92
#
# Licensed under the Giovix92 License, Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You can find a copy here:
# https://github.com/Giovix92/CIbot/blob/master/LICENSE
VERSION="4.0.1"

# Main variables must be set here!
# Token of your Telegram bot:
TELEGRAM_TOKEN=
# Chat ID of your desired channel/group to post in:
TELEGRAM_CHAT=
# Your personal ID in order to allow your bot to send you pms (OPTIONAL):
TELEGRAM_CHAT_USER=
# Your server IP:
IP=
# Your server username:
USERNAME=
# Your server password:
PASSWORD=

# Build variables
# Prevent syncing from your ROM's repo:
NOSYNC=
# Cleans out/ dir:
CLEAN=
# Advanced logging:
VERBOSE=
# Whether to use or not server for building:
SERVER=
# Prevent using ccache:
NOCCACHE=
# Power off of local machine after building:
POWEROFF=
# Retry building on fail, useful for metalava errors:
RETRYONFAIL=
# Disables most of the messages, including telegram ones:
QUIET=
# Jobs to use:
jobs=

# Devices and roms
# Here you can find some of the examples of device + ROM "inputs".
# Feel free to add yours! Every AOSP is supported!
# Note:
for var in "$@"
do
case $var in
  tissot)
  DEVICE="tissot"
  COMMONDIR="msm8953-common"
  KERNELDIR="msm8953"
  VENDOR="xiaomi"
  ARCH="arm64"
  KERNELUSED="perf+"
  ;;
  lavender)
  DEVICE="lavender"
  VENDOR="xiaomi"
  COMMONDIR="sdm660-common"
  KERNELDIR="lavender"
  ARCH="arm64"
  KERNELUSED="perf+"
  ;;
  tulip)
  DEVICE="tulip"
  VENDOR="xiaomi"
  KERNELDIR="sdm660"
  COMMONDIR="sdm660-common"
  ARCH="arm64"
  KERNELUSED=
  ;;
  cepheus)
  DEVICE="cepheus"
  VENDOR="xiaomi"
  KERNELDIR="cepheus"
  COMMONDIR=
  ARCH="arm64"
  KERNELUSED="Quantic Kernel"
  ;;
  twrp)
  WORKINGDIR=
  BUILDTYPE="TWRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="3.3"
  TYPE="RECOVERY"
  var2="twrp"
  KERNELUSED="Prebuilt (perf+)"
  ;;
  shrp)
  WORKINGDIR=
  REMOTEDIR=
  BUILDTYPE="SHRP"
  VARIANT="eng"
  WORKNAME="omni"
  ANDROIDVER="2.3"
  TYPE="RECOVERY"
  MAKECMD="recoveryimage"
  var2="twrp"
  KERNELUSED="Prebuilt (perf+)"
  ;;
  revenge11)
  WORKINGDIR=
  REMOTEDIR=
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="R"
  MAKECMD="bacon"
  TYPE="ROM"
  var2="revenge11"
  ;;
  revenge10)
  WORKINGDIR=
  REMOTEDIR=
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="Q"
  MAKECMD="bacon"
  TYPE="ROM"
  var2="revenge10"
  ;;
  revenge9)
  WORKINGDIR=
  REMOTEDIR=
  BUILDTYPE="RevengeOS"
  VARIANT="userdebug"
  WORKNAME="revengeos"
  ANDROIDVER="P"
  MAKECMD="bacon"
  TYPE="ROM"
  var2="revenge9"
  ;;
  descendant)
  WORKINGDIR=
  REMOTEDIR=
  BUILDTYPE="Descendant"
  VARIANT="userdebug"
  WORKNAME="descendant"
  ANDROIDVER="Q"
  MAKECMD="descendant"
  TYPE="ROM"
  var2="descendant"
  ;;
  help)
  echo "Giovix92 CI Bot v$(echo $VERSION)"
  echo "Command usage: bot.sh device romtype"
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
