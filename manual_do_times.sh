#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

log_dir=/home/hawkinsw/manual/

if [ $# -ne 1 ]; then
  echo "$0 <variant>";
  exit
fi

variant=$1
shift

{
  ./manual_times.py --variant ${variant} --input_dir ${log_dir} --output_dir ${log_dir}
}

cd ${iwashere}
