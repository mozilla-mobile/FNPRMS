#!/usr/bin/env bash

ADB="/home/hawkinsw/Android/Sdk/platform-tools/adb"
homeactivity_start_command='am start-activity --start-profiler PROFILE_FILE --streaming org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity'
applink_start_command='am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW --start-profiler PROFILE_FILE --streaming org.mozilla.fenix.performancetest/org.mozilla.fenix.IntentReceiverActivity'
apk_url_template="https://index.taskcluster.net/v1/task/project.mobile.fenix.v2.performance-test.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
log_dir=/home/hawkinsw/run_logs/

. common.sh

function generate_profile {
  apk=$1
  shift
  profile_file_path=$1
  shift
  start_command_template=$1

  remote_profile_file="/data/local/tmp/temp.trace"
  escaped_remote_profile_file=$(echo ${remote_profile_file} | sed 's/\//\\\//g')

  start_command=`echo ${start_command_template} | sed "s/PROFILE_FILE/${escaped_remote_profile_file}/"`

  maybe_create_dir $profile_file

  $ADB shell rm -f ${remote_profile_file}
  $ADB uninstall org.mozilla.fenix.nightly > /dev/null 2>&1
  $ADB uninstall org.mozilla.fenix.performancetest > /dev/null 2>&1
  $ADB install -t $apk

  if [ $? -ne 0 ]; then
    echo 'Error occurred installing the APK!' > $log_output_file
    return
  fi

  echo "Profiling by using $start_command"
  $ADB shell "$start_command"

  # sleep here in case it takes a while for the app to start.
  # We don't want to stop it before it starts.
  sleep 10

  echo "Stopping the profiler and the process."
  $ADB shell "am profile stop org.mozilla.fenix.performancetest"
  sleep 2
  $ADB shell "am force-stop org.mozilla.fenix.performancetest"

  echo "Downloading profile."
  $ADB pull ${remote_profile_file} ${profile_file_path} > /dev/null 2>&1
}

log_base=`date +"%Y.%-m.%-d"`
run_log="${log_dir}/${log_base}.log"
ha_profile_file_path="${log_dir}/${log_base}-ha-trace/"
al_profile_file_path="${log_dir}/${log_base}-al-trace/"
download_apk_path=`printf "%s/%s/" \`pwd\` \`date +"%Y/%-m/%-d"\``;
download_apk_file=`printf "%s/%s" ${download_apk_path} profile-nightly.apk`;

maybe_create_dir $log_dir
maybe_create_dir $al_profile_file_path
maybe_create_dir $ha_profile_file_path
maybe_create_file $run_log
maybe_create_dir $download_apk_path

{
  apk_downloaded=0
  for i in {1..5}; do
    download_apk ${apk_url_template} ${download_apk_file}
    result=$?
    if [ $result -eq 0 ]; then
      echo "Downloaded the nightly APK."
      apk_downloaded=1
      break
    fi
    echo "Trying again to download the nightly apk (error ${result})."
  done

  if [ $apk_downloaded -eq 0 ]; then
    echo "Failed to download an APK."
    maybe_create_file "${log_dir}/${log_base}-ha.log"
    maybe_create_file "${log_dir}/${log_base}-al.log"
    echo "Failed to download an APK." > "${log_dir}/${log_base}-ha.log"
    echo "Failed to download an APK." > "${log_dir}/${log_base}-al.log"
    exit
  fi

  generate_profile "$download_apk_file" "${ha_profile_file_path}" "$homeactivity_start_command"
  generate_profile "$download_apk_file" "${al_profile_file_path}" "$applink_start_command"
}

#cwd=`pwd`
#cd $log_dir
#git add *.log
#git commit -m "$log_base"
#git push origin master -q
#cd $cwd
