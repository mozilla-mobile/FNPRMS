#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Download the most recent build of Fenix (performancetest variant)
# and run it once.

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

function run {
  apk=$1
  shift
  start_command=$1

  $ADB uninstall org.mozilla.fenix.performancetest > /dev/null 2>&1
  $ADB install -t ${apk}

  if [ $? -ne 0 ]; then
    echo 'Error occurred installing the APK!' > ${log_file}
  else
    echo "Starting by using ${start_command}"
    $ADB shell "${start_command}"
  fi
}

homeactivity_start_command='am start-activity org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity'
applink_start_command='am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.performancetest/org.mozilla.fenix.IntentReceiverActivity'
apk_url_template="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.mobile.fenix.v2.performance-test.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
log_dir=/home/hawkinsw/run_logs/
test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
downloaded_apk_path=`printf "%s/%s/" \`pwd\` \`date +"%Y/%m/%-d"\``;
downloaded_apk_file=`printf "%s/%s" ${downloaded_apk_path} nightly.apk`;
apk_downloaded=0
apk_download_attempts=5

{
  for i in `seq 1 ${apk_download_attempts}`; do
    download_apk ${apk_url_template} ${test_date} ${downloaded_apk_file}
    result=$?
    if [ ${result} -eq 0 ]; then
      apk_downloaded=1
      break
    fi
    echo "Trying again to download the nightly apk (error ${result})."
  done

  if [ ${apk_downloaded} -eq 0 ]; then
    echo "Error: Failed to download an APK."
  else
    echo "Running Fenix"
    run ${downloaded_apk_file} "${homeactivity_start_command}"
  fi
}

cd ${iwashere}
