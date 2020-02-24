#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Use gnuplot to graph test results.

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

DEVICEID=$1
PRODUCTID=$2

. common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
. common.sh

log_dir=$fpm_log_dir

cwd=`pwd`
cd ${log_dir}

gnuplot ${iamhere}/ha.plot
gnuplot ${iamhere}/al.plot
gnuplot ${iamhere}/hanoob.plot

#git add *.png
#git commit -m "${log_base} Graph the results."
#git push fenix-mobile master -q
cd ${cwd}

cd ${iwashere}
