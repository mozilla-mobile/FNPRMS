#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Manually run _product_ under the _use_case_ use case where the application
# is stored in _apk_.

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

apk_file=$1
shift
use_case=$1
shift
product=$1

if [ \( "X${apk_file}" == "X" \) -o \( "X${use_case}" == "X" \) -o \( "X${product}" == "X" \) ]; then
  echo "usage: <apk file to test> <ha|al|hanoob> <fennec|fenix-nightly|fenix-performance>"
  exit 1
fi

ifc=$(intent_for_configuration ${use_case} ${product})
if [ $? -ne 0 ]; then
  echo "Cannot get intent for use case/product pair."
  exit
fi

package_name=$(package_name_for_product ${product})
if [ $? -ne 0 ]; then
  echo "Cannot get intent for use case/product pair."
  exit
fi

log_dir=/opt/fnprms/manual/
test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"

maybe_create_dir ${log_dir}

maybe_create_file "${log_dir}/${log_base}-${use_case}.log"

run_test ${apk_file} "${log_dir}/${log_base}-${use_case}.log" "${package_name}" "am start-activity ${ifc}" 25

cd ${iwashere}
