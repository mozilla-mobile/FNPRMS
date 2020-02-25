#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Generate csv- and json-formatted files containing test results
# for all the raw test data in _log_dir_ for the Fenix product
# nightly variant.

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
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"

maybe_create_file ${run_log}


{
  ./times.py --product fennec-nightly-g5 --input_dir ${log_dir} --output_dir ${log_dir}
} >> ${run_log} 2>&1

cwd=`pwd`
cd ${log_dir}
#git add *.csv
#git add *.json
#git add *.log
#git commit -m "${log_base} update stats"
#git push fenix-mobile master -q
cd ${cwd}

cd ${iwashere}
