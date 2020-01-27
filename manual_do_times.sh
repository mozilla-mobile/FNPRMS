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

. common.sh

log_dir=/opt/fnprms/manual/

if [ $# -ne 1 ]; then
  echo "$0 <fennec|fenix-nightly|fenix-performance>";
  exit
fi

product=$1
shift

validate_product ${product}
if [ $? -ne 0 ]; then
  echo "Invalid product name."
  exit
fi

{
  ./times.py --product ${product} --input_dir ${log_dir} --output_dir ${log_dir}
}

cd ${iwashere}
