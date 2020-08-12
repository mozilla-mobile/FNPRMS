#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

DEVICEID=$1
PRODUCTID=$2
DATESTAMP=$3
TESTTYPE=$4

if [ ! -n "$DATESTAMP" ]; then
    echo "Date stamp (YYYY.MM.DD) argument not supplied, exiting";
    exit 1;
fi

if [ ! -n "$TESTTYPE" ]; then
    echo "Test type (al/ha/hanoob) argument not supplied, exiting";
    exit 1;
fi

. common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
. common.sh $DATESTAMP

LOGDIR=$fpm_log_dir
VAL=$(./times.py --input_dir "$LOGDIR" --output_dir "$LOGDIR" --product "$PRODUCTID" --date_stamp "$DATESTAMP" --test_type "$TESTTYPE")

echo $VAL
