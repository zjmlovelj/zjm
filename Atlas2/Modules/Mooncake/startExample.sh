#!/bin/sh

srcroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $srcroot
# This is to support Mink1 and Mink2 binaries installed on the build machine.
get_mink_binary_name()
{
    if [ -z "$MINK2_BIN" ]
    then
          echo "mink"
    else
        echo $MINK2_BIN
    fi
}

# temp_overlay_root="${srcroot}/build/temp_root"

# build project
# $(get_mink_binary_name) build -d "$temp_overlay_root" || exit $?

# Cleanup the current content of global Atlas2 dir
# global_atlas2_path="/Users/$(whoami)/Library/Atlas2"
# rm -rf "${global_atlas2_path}"/*

# Install the content of Atlas2 dir
# temp_user_home_path="${temp_overlay_root}/Users/$(whoami)"
# temp_atlas2_path="${temp_user_home_path}/Library/Atlas2"

# cp -r "${temp_atlas2_path}"/* "${global_atlas2_path}"

mkdir -p ~/Library/Atlas2/Modules/coverage
/usr/local/bin/AtlasLua $srcroot/Modules/Schooner/Compiler/BuildSchoonerSequence.lua -m $srcroot/Assets/MainTable.csv -l $srcroot/Assets/LimitTable.csv -c $srcroot/Assets/ConditionTable.csv -t $srcroot/Assets/TestDefinitions -o $srcroot/Modules/coverage/coverage.lua
# Run Atlas2
/usr/local/bin/AtlasLauncher stop
# /usr/local/bin/AtlasSigner skeleton skeleton.plist
# /usr/local/bin/AtlasSigner skeleton.plist ~/Library/Atlas2
/usr/local/bin/AtlasLauncher start station.plist 

# M1 
# arch -x86_64 /usr/local/bin/AtlasLauncher stop
# arch -x86_64 /usr/local/bin/AtlasLauncher start station.plist 

open /AppleInternal/Applications/AtlasUI.app &
open /AppleInternal/Applications/AtlasRecordsUI.app &


