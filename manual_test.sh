#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

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

maybe_create_file "${log_dir}/${log_base}-ha.log"

run_test ${apk_file} "${log_dir}/${log_base}-ha.log" "${package_name}" "${start_command}" 100

cd ${iwashere}
