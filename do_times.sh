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
DATESTAMP=$3
if [ ! -n "$DATESTAMP" ]; then
    DATESTAMP=`date +"%Y.%m.%d"`
fi

. common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
. common.sh $DATESTAMP

log_dir=$fpm_log_dir
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"

maybe_create_file ${run_log}

cd ${fpm_prefix_dir}

{
  ./times.py --product ${fpm_product} --input_dir ${log_dir} --output_dir ${log_dir}
} >> ${run_log} 2>&1

stem=${fpm_dev_name}-${fpm_product}

cwd=`pwd`
cd ${log_dir}

mv al-results.csv ${fpm_results_dir}/${stem}-al-results.csv
mv al-results.json ${fpm_results_dir}/${stem}-al-results.json
mv ha-results.csv ${fpm_results_dir}/${stem}-ha-results.csv
mv ha-results.json ${fpm_results_dir}/${stem}-ha-results.json
mv hanoob-results.csv ${fpm_results_dir}/${stem}-hanoob-results.csv
mv hanoob-results.json ${fpm_results_dir}/${stem}-hanoob-results.json

cd ${cwd}

echo "finished ${stem} at " `date`
