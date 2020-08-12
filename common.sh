#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Common functions used throughout FNPRMS

# test date, in ISO form "2020.02.21"
DATESTAMP=$1
export test_date="${DATESTAMP}"
echo "with date: ${DATESTAMP}"

# number of harness iterations
export fpm_iterations=100

# base directory for harness output
export fpm_prefix_dir=/opt/mozilla/FNPRMS

# directory for results in (csv, json) for checkin to github
export fpm_results_dir=${fpm_prefix_dir}_results

# To continue, product and device must be set.
if [ ! -n "$fpm_dev_name" ] || [ ! -n "$fpm_product" ]; then
    echo "Exiting early as product and or device must be set to continue."
else
    # directory for harness output from scheduled runs
    export fpm_log_dir=${fpm_prefix_dir}_${HOSTNAME}_${fpm_dev_name}_${fpm_product}

    # application binary location and name
    test_date_path=`echo $test_date | sed 's/\./\//g'`
    export dl_apk_path=`printf "%s/%s/%s" \`pwd\` "bin" "${test_date_path}"`;
    export dl_apk_name=${fpm_product}.apk

    # Report environmental and arguments to log file
    echo "with iterations:" ${fpm_iterations}
    echo "with prefix directory:" ${fpm_prefix_dir}
    echo "with log directory:" ${fpm_log_dir}
fi


# download_apk
#
# Params:
# 1: url_template
# 2: date_to_fetch
# 3: output_file_path
#
# Download the apk from the url built by replacing all instances of DATE
# in _url_template_ with the _date_to_fetch and save it to _output_file_path.
#
# Output:
# Loggable diagnostic information
#
# Return Value:
# 0 if the apk was downloaded successfully; curl's return value, otherwise.
function download_apk {
  url_template=$1
  shift
  date_to_fetch=$1
  shift
  output_file_path=$1
  result=0

  # If the apk already exists, don't bother getting it again.
  echo "Looking for apk in ${output_file_path}"
  if [ -e ${output_file_path} ]; then
    echo "Not downloading a new apk; using existing."
    return 0
  fi

  apk_download_url=`echo ${apk_url_template} | sed "s/DATE/${date_to_fetch}/g"`;
  echo "Downloading apk: ${apk_download_url}"
  curl -fsL --create-dirs --output ${output_file_path} ${apk_download_url} 2>&1 > /dev/null
  result=$?
  echo "Done downloading apk."
  return ${result}
}

# maybe_create_dir
#
# Params:
# 1: filedir
#
# Create _filedir_ directory if it does not already exist. This function will
# create any parent directories necessary to make it possible to create
# _filedir_.
#
# Return value:
# The return value of mkdir
function maybe_create_dir {
  filedir=$1
  mkdir -p ${filedir} >/dev/null 2>&1
}

# maybe_create_file
#
# Params:
# 1: filepath
#
# Create _filepath_ file if it does not already exist. This function will
# create any directories necessary to make it possible to create _filepath_.
#
# Return value:
# The return value of touch
function maybe_create_file {
  filepath=$1
  maybe_create_dir $(dirname ${filepath})
  touch ${filepath}
}

# run_test
#
# Params:
# 1: apk
# 2: log_file
# 3: package_name
# 4: start_command
# 5: tests
# 6: finishonboarding
#
# Run install _apk_ on the system and execute it _tests_ times using the
# _start_command_. If _finishonboarding_ is true, the application will be run
# without onboarding. All results are logged in _log_file_. For more information
# about the methodology employed by this test, see
# https://docs.google.com/document/d/1HhXjAnu5tRv9Uo_bqnNa6S8LbF6WNAlSYbFrIQiGz_g/edit.
#
# Output:
# Loggable diagnostic information
#
# Return Value:
# None
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
  shift
  finishonboarding=$1

  warmup_start_command=${start_command}
  if [ "Xtrue" == "X${finishonboarding}" ]; then
    warmup_start_command=`echo ${start_command} | sed 's/start-activity/start-activity --ez performancetest true/'`
  fi

  rm -f ${log_file} > /dev/null 2>&1
  maybe_create_file ${log_file}

  # Do the apk installation.
  $ADB uninstall ${package_name} > /dev/null 2>&1
  $ADB install -t ${apk}

  if [ $? -ne 0 ]; then
    echo 'Error occurred installing the APK!' > ${log_file}
    return
  fi

  # Now, do a single start to get all that stuff out of the way.
  $ADB shell "${warmup_start_command}"
  # Sleep here in case it takes a while for the app to start.
  # We don't want to stop it before it starts.
  sleep 5
  $ADB shell "am force-stop ${package_name}"

  # This will clear all processes that are 'safe to kill'. Do
  # this to try to eliminate noise.
  $ADB shell "am kill-all"

  # Clearing the log here so that we don't record the time of the
  # first start (above)
  $ADB logcat --clear
  $ADB logcat -G 2M

  # Add start_command to log file
  echo "Test using ${start_command}" >> ${log_file} 2>&1

  for i in `seq ${tests}`; do
    $ADB logcat --clear
    echo "FNPRMS Iteration ${i}" >> ${log_file} 2>&1

    $ADB shell "${start_command}"

    # Sleep here in case it takes a while for the app to start.
    # We don't want to stop it before it starts.
    sleep 5
    $ADB shell "input keyevent HOME"
    sleep 5
    $ADB shell "am force-stop ${package_name}"
    $ADB logcat -d >> ${log_file} 2>&1
    echo "" >> ${log_file} 2>&1

    # Wait a bit after killing the process so Android has time to
    # reclaim memory and generally "settle down" to reduce
    # statistical noise.
    sleep 1
  done;
}
