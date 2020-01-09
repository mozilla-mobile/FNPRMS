#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

log_dir=/home/hawkinsw/manual/

if [ $# -ne 1 ]; then
  echo "$0 <product>";
  exit
fi

product=$1
shift

validate_product ${product}
if [ $? -ne 0 ]; then
  echo "Invalid product name."
  exit
fi

{
  ./times.py --product ${product} --input_dir ${log_dir} --output_dir ${log_dir}
}

cd ${iwashere}
