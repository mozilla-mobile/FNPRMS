#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Generate csv- and json-formatted files containing test results
# for all the raw test data in _log_dir_ for _product_.

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

log_dir=/opt/fnprms/manual/
# multi-device was added for FNPRMS in SF, which isn't where manual_test is expected to run.
#DEVICEID=$1
PRODUCTID=$1

# . common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
. common.sh


{
  ./times.py --product $PRODUCTID --input_dir ${log_dir} --output_dir ${log_dir}
}

cd ${iwashere}
