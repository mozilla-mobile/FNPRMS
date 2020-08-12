#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

DEVICEID=$1
PRODUCTID=$2
TESTTYPE=$3
DATESTAMP=$4

if [ ! -n "$DEVICEID" ]; then
    echo "Device id argument not supplied, exiting";
    exit 1;
fi

if [ ! -n "$PRODUCTID" ]; then
    echo "Product id (fenix-nightly/fennec) argument not supplied, exiting";
    exit 2;
fi

if [ ! -n "$TESTTYPE" ]; then
    echo "Test type (al/ha/hanoob) argument not supplied, exiting";
    exit 3;
fi

if [ ! -n "$DATESTAMP" ]; then
    echo "Date (2020.06.04) argument not supplied, exiting";
    exit 3;
fi

. common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
. common.sh $DATESTAMP

LOGDIR=$fpm_log_dir
VAL=$(./times.py --input_dir "$LOGDIR" --output_dir "$LOGDIR" --product "$PRODUCTID" --test "$TESTTYPE" --date "${test_date}")

# Convert DEVICEID into something rational and consistent for influx.
DEVICE=`echo ${fpm_dev_name} | sed 's/_/-/g'`

# Convert TESTTYPE into something rational and consistent for influx.
TYPE="unknown"
if [ "$TESTTYPE" == "al" ]; then
    TYPE=view
fi
if [ "$TESTTYPE" == "ha" ]; then
    TYPE=main-pre-onboard
fi
if [ "$TESTTYPE" == "hanoob" ]; then
    TYPE=main-post-onboard
fi

./post_results_influx.sh "$DEVICE" "$PRODUCTID" "$TYPE" "$VAL" "${test_date}"
