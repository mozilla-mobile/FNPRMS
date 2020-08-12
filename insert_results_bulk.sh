#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

DEVICEID=$1
PRODUCTID=$2
TESTTYPE=$3


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


. common_devices.sh $DEVICEID
. common_products.sh $PRODUCTID
LOGDIR=$fpm_log_dir

#DATES=( 2020.05.01 2020.05.02 2020.05.03 2020.05.04 2020.05.05 2020.05.06 2020.05.07 2020.05.08 2020.05.09 2020.05.10 2020.05.11 2020.05.12 2020.05.13 2020.05.14 2020.05.15 2020.05.16 2020.05.17 2020.05.18 2020.05.19 )

#DATES=( 2020.05.02 2020.05.14 )
DATES=( 2020.05.29 2020.05.30 )

for DATESTAMP in "${DATES[@]}"
do
    . common.sh $DATESTAMP
    VAL=$(./times.py --input_dir "$LOGDIR" --output_dir "$LOGDIR" --product "$PRODUCTID" --date_stamp "$DATESTAMP" --test_type "$TESTTYPE")
    ./insert_results_specific.sh "$DEVICEID" "$PRODUCTID" "$TESTTYPE" "$DATESTAMP"
done

