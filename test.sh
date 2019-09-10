#!/usr/bin/env bash

tests=5
ADB="/home/hawkinsw/Android/Sdk/platform-tools/adb"
homeactivity_start_command='am start-activity org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity'
applink_start_command='am start-activity -t "text/html" -d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.nightly/org.mozilla.fenix.IntentReceiverActivity'
apk_url_template="https://index.taskcluster.net/v1/task/project.mobile.fenix.v2.nightly.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"
log_dir=/home/hawkinsw/run_logs/

function download_apk { 
  date_to_fetch=`date +"%Y.%-m.%-d"`;
  output_file_path=`printf "%s/%s/%s" \`pwd\` \`date +"%Y/%-m/%-d"\` nightly.apk`;
  echo $output_file_path

  # If the apk already exists, don't bother getting it again.
  if [ -e $output_file_path ]; then
    return 0
  fi

  apk_download_url=`echo $apk_url_template | sed "s/DATE/${date_to_fetch}/g"`;
  curl -fsL --create-dirs --output $output_file_path $apk_download_url 2>&1 > /dev/null
  return $?
}


function maybe_create_dir {

  filedir=$1

  mkdir -p $filedir >/dev/null 2>&1
}

function maybe_create_file {
  filepath=$1
  another=0

  maybe_create_dir $(dirname $filepath)
  touch $filepath
}

function run_test {
  apk=$1
  shift
  tag=$1
  shift
  start_command=$1

  log_output_file="run_logs/${tag}.log"

  rm -f $log_output_file > /dev/null 2>&1

  maybe_create_file $log_output_file

  $ADB logcat --clear
  for i in `seq $tests`; do
    if [ $i -eq 1 ]; then
      $ADB uninstall org.mozilla.fenix.nightly > /dev/null 2>&1
      $ADB install -t $apk

      if [ $? -ne 0 ]; then
        echo 'Error occurred installing the APK!' > $log_output_file
      fi
    fi

    echo "Starting by using $start_command"
    $ADB shell "$start_command"
    # sleep here in case it takes a while for the app to start.
    # We don't want to stop it before it starts.
    sleep 10 
    $ADB shell "am force-stop org.mozilla.fenix.nightly"
  done;

  $ADB logcat -d >> $log_output_file 2>&1
}

log_base=`date +"%Y.%-m.%-d"`
run_log="${log_dir}/${log_base}.log"

maybe_create_dir $log_dir
maybe_create_file $run_log

{
  apk_downloaded=0
  for i in {1..5}; do
    downloaded_apk_location=$(download_apk)
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

  run_test $downloaded_apk_location "${log_base}-ha" "$homeactivity_start_command"
  run_test $downloaded_apk_location "${log_base}-al" "$applink_start_command"
} > $run_log 2>&1

cwd=`pwd`
cd $log_dir
git add *.log
git commit -m "$log_base"
git push origin master -q
cd $cwd
