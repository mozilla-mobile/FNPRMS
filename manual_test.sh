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
  package_name=$1
  shift
  start_command=$1
  shift
  tests=$1

  rm -f ${log_file} > /dev/null 2>&1
  maybe_create_file ${log_file}

  # This will clear all processes that are 'safe to kill'. Do
  # this to try to eliminate noise.
  $ADB shell "am kill-all"

  $ADB logcat --clear
  for i in `seq ${tests}`; do
    if [ $i -eq 1 ]; then
      $ADB uninstall ${package_name} > /dev/null 2>&1
      $ADB install -t ${apk}

      if [ $? -ne 0 ]; then
        echo 'Error occurred installing the APK!' > ${log_file}
      fi
    fi

    echo "Starting by using ${start_command}"
    # sleep here in case it takes a while for the app to start.
    # We don't want to stop it before it starts.

    for i in `seq 3`; do
      $ADB shell "${start_command}"
      sleep 5 
      $ADB shell "am force-stop ${package_name}"
    done
  done;

  $ADB logcat -d >> ${log_file} 2>&1
}

apk_file=$1
shift
package_name=$1
shift
start_command=$1
shift

if [ \( "X${apk_file}" == "X" \) -o \( "X${package_name}" == "X" \) -o \( "X${start_command}" == "X" \) ]; then
  echo "usage: <apk file to test> <package name> <command [to am] to start the apk>"
  exit 1
fi

log_dir=/home/hawkinsw/manual/
test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
run_log="${log_dir}/${log_base}.log"

maybe_create_dir ${log_dir}

maybe_create_file "${log_dir}/${log_base}-al.log"

run_test ${apk_file} "${log_dir}/${log_base}-al.log" "${package_name}" "${start_command}" 100

cd ${iwashere}
