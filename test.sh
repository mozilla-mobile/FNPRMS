#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

homeactivity_start_command='am start-activity org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity'
applink_start_command='am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.performancetest/org.mozilla.fenix.IntentReceiverActivity'
apk_url_template="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.mobile.fenix.v2.performance-test.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
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
maybe_create_file "${log_dir}/${log_base}-hanoob.log"

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
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-ha.log" "org.mozilla.fenix.performancetest" "${homeactivity_start_command}" 100
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-al.log" "org.mozilla.fenix.performancetest" "${applink_start_command}" 100
    run_test ${downloaded_apk_file} "${log_dir}/${log_base}-hanoob.log" "org.mozilla.fenix.performancetest" "${homeactivity_start_command}" 100 true
  fi
} >> ${run_log} 2>&1

cwd=`pwd`
cd ${log_dir}
sweep_files_older_than 30 ${log_dir}
git add *.log
git commit -m "${log_base} test"
git push fenix-mobile master -q
cd ${cwd}


cd ${iwashere}
