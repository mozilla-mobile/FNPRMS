#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Run startup performance tests on the most recent version of Fenix nightly
# for each of the three use cases.

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
downloaded_apk_file=`printf "%s/%s" ${dl_apk_path} ${dl_apk_name}`;
apk_downloaded=0
apk_download_attempts=5

# Create, if necesary all the files and directories needed to store the
# log files generated by running the tests.
maybe_create_dir ${log_dir}
maybe_create_file ${run_log}
maybe_create_dir ${dl_apk_path}

maybe_create_file "${log_dir}/${log_base}-ha.log"
maybe_create_file "${log_dir}/${log_base}-al.log"
maybe_create_file "${log_dir}/${log_base}-hanoob.log"

#sanity check
echo "run log is: ${run_log}"

# Do the actual work! All diagnostic output from these actions will
# be logged to _run_log_.
{

  # Try _apk_download_attempts times to download the apk to test.
  for i in `seq 1 ${apk_download_attempts}`; do
    download_apk ${apk_url_template} ${test_date} ${downloaded_apk_file}
    result=$?
    if [ ${result} -eq 0 ]; then
      apk_downloaded=1
      break
    fi
    echo "Trying again to download the nightly apk (error ${result})."
  done

  # Check to see if we could download an apk.
  if [ ${apk_downloaded} -eq 0 ]; then
    echo "Error: Failed to download an APK."
     ./signal_alert.sh "${downloaded_apk_file} DNE" "No ${fpm_dev_name} apk"
    exit 405;
  else
    # Run each of the three use cases 10 times.
    echo "Running tests"
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-ha.log" "${apk_package}" "${homeactivity_start_command}" $fpm_iterations
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-al.log" "${apk_package}" "${applink_start_command}" 25
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-hanoob.log" "${apk_package}" "${homeactivity_start_command}" $fpm_iterations true
  fi
} >> ${run_log} 2>&1

cd ${iwashere}
