#!/usr/bin/env bash

# usage: ./hot-start.sh <path-to-apk>

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
cd ${iamhere}

. common.sh

ADB=adb
APP_ID=org.mozilla.fenix.debug

function run_test {
  apk=$1
  shift
  log_file=$1
  shift
  start_command=$1
  shift
  tests=$1

  rm -f ${log_file} > /dev/null 2>&1
  maybe_create_file ${log_file}

  adb shell setprop log.tag.FenixPerf VERBOSE # enable hot start logging.

  for i in `seq ${tests}`; do
    if [ $i -eq 1 ]; then
      $ADB uninstall $APP_ID > /dev/null 2>&1
      $ADB install -t ${apk}

      if [ $? -ne 0 ]; then
        echo 'Error occurred installing the APK!' > ${log_file}
      fi
    fi

    echo ""
    echo "--- Iteration $i ---"

    $ADB shell pm clear $APP_ID
    $ADB shell am kill-all # kill other backgrounded processes

    # First run.
    $ADB shell "${start_command}"
    sleep 10 # allow settle.
    $ADB shell input keyevent 3 # send Home button press
    sleep 2

    $ADB shell am kill $APP_ID
    $ADB shell am force-stop $APP_ID
    $ADB logcat --clear
    sleep 5 # allow settle.

    # Second run.
    adb shell "${start_command}"
    sleep 10 # allow settle.
    $ADB shell input keyevent 3 # send Home button press
    sleep 2

    # Hot start
    adb shell "${start_command}"
    sleep 10 # allow settle.

    $ADB logcat -d | grep "hot start" >> ${log_file} 2>&1
  done;
}

homeactivity_start_command="am start-activity $APP_ID/org.mozilla.fenix.HomeActivity"
applink_start_command="am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW $APP_ID/org.mozilla.fenix.IntentReceiverActivity"
apk_url_template="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.mobile.fenix.v2.performance-test.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
log_dir=./sb/logs
test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"
downloaded_apk_path=`printf "%s/%s/" \`pwd\` \`date +"%Y/%m/%d"\``;
downloaded_apk_file=`printf "%s/%s" ${downloaded_apk_path} nightly.apk`;
apk_downloaded=0
apk_download_attempts=5

maybe_create_dir ${log_dir}
maybe_create_file ${run_log}
#maybe_create_dir ${downloaded_apk_path}

maybe_create_file "${log_dir}/hot-start.log"

echo "Running tests"
run_test $1 "${log_dir}/hot-start.log" "${homeactivity_start_command}" 3
