#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
cd ${iamhere}

. common.sh

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

  $ADB logcat --clear
  for i in `seq ${tests}`; do
    if [ $i -eq 1 ]; then
      $ADB uninstall org.mozilla.fenix.nightly > /dev/null 2>&1
      $ADB install -t ${apk}

      if [ $? -ne 0 ]; then
        echo 'Error occurred installing the APK!' > ${log_file}
      fi
    fi

    echo "Starting by using ${start_command}"
    $ADB shell "${start_command}"
    # sleep here in case it takes a while for the app to start.
    # We don't want to stop it before it starts.
    sleep 10 
    $ADB shell "am force-stop org.mozilla.fenix.nightly"
  done;

  $ADB logcat -d >> ${log_file} 2>&1
}

homeactivity_start_command='am start-activity org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity'
applink_start_command='am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.nightly/org.mozilla.fenix.IntentReceiverActivity'
apk_url_template="https://index.taskcluster.net/v1/task/project.mobile.fenix.v2.nightly.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
log_dir=/home/hawkinsw/run_logs/
test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"
downloaded_apk_path=`printf "%s/%s/" \`pwd\` \`date +"%Y/%m/%d"\``;
downloaded_apk_file=`printf "%s/%s" ${downloaded_apk_path} nightly.apk`;
apk_downloaded=0
apk_download_attempts=5

maybe_create_dir ${log_dir}
maybe_create_file ${run_log}
maybe_create_dir ${downloaded_apk_path}

maybe_create_file "${log_dir}/${log_base}-ha.log"
maybe_create_file "${log_dir}/${log_base}-al.log"

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
    echo "Running tests"
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-ha.log" "${homeactivity_start_command}" 5
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-al.log" "${applink_start_command}" 5
  fi
} >> ${run_log} 2>&1

cwd=`pwd`
cd ${log_dir}
git add *.log
git commit -m "${log_base} test"
git push fenix-mobile master -q
cd ${cwd}

sweep_files_older_than 3 ${log_dir}

cd ${iwashere}
