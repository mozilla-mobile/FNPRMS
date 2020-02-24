#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# NB: ordered before common.sh script is invoked
# muti-device setup, pass in integer for device id desired
DEVICEID=$1

# List of devices and names attached to the system.
if [ "$DEVICEID" -eq "1" ]; then
    export fpm_dev_id=1
    export fpm_dev_serial=9C081FFBA002DU
    export fpm_dev_name=pixel_4_xl
fi

if [ "$DEVICEID" -eq "2" ]; then
    export fpm_dev_id=2
    export fpm_dev_serial=FA79G1A05075
    export fpm_dev_name=pixel_2
fi

if [ "$DEVICEID" -eq "3" ]; then
    export fpm_dev_id=3
    export fpm_dev_serial=RF8MB1E9NHB
    export fpm_dev_name=samsung_galaxy_s10
fi

if [ "$DEVICEID" -eq "4" ]; then
    export fpm_dev_id=4
    export fpm_dev_serial=956AX0EZEZ
    export fpm_dev_name=pixel_3a_xl
fi

# Constant for use in other scripts to be able to easily locate
# adb on the system.
# NB: Mozilla builds need to have adb and android tools in sync. Assume
# this is already configured correctly in the enviornment, but note
# exact location here.
fpm_adb="/home/bkoz/.mozbuild/android-sdk-linux/platform-tools/adb"
export ADB="${fpm_adb} -s ${fpm_dev_serial}"

# Report results.
echo "id: ${fpm_dev_id}"
echo "serial: ${fpm_dev_serial}"
echo "name: ${fpm_dev_name}"
echo "adb: $ADB"
