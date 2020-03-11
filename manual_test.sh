#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Manually run _product_ under the _use_case_ use case where the application
# is stored in _apk_.

USAGE="usage: <apk file to test> <al|hanoob> <fennec|fenix-nightly|fenix-performance|fennec-nightly|fennec-nightly-g5>"

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

apk_file=$1
use_case=$2

# multi-device was added for FNPRMS in SF, which isn't where manual_test is expected to run.
#DEVICEID=$1
PRODUCTID=$3

# . common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
. common.sh

case $use_case in
  al)
    command=$applink_start_command
    ;;
  hanoob)
    command=$homeactivity_start_command
    ;;
  # we're not actively using ha so I excluded that option.
esac

if [ \( "X${apk_file}" == "X" \) -o \( "X${command}" == "X" \) -o \( "X${apk_package}" == "X" \) ]; then
  echo $USAGE
  exit 1
fi

log_dir=/opt/fnprms/manual/
test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"

maybe_create_dir ${log_dir}

maybe_create_file "${log_dir}/${log_base}-${use_case}.log"

run_test $apk_file "${log_dir}/${log_base}-${use_case}.log" "$apk_package" "$command" 25

cd ${iwashere}
