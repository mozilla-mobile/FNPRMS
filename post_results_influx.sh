#!/usr/bin/env bash

DEVICE=$1
PRODUCTID=$2
METRIC=$3
VALUE=$4
DATE=$5

if [ ! -n "$DEVICE" ]; then
    echo "Device argument empty, exiting";
    exit 1;
fi

if [ ! -n "$PRODUCTID" ]; then
    echo "Product (fenix-nightly/fennec-nightly) argument empty, exiting";
    exit 2;
fi

if [ ! -n "$METRIC" ]; then
    echo "Metric (view/main-post-onboard) argument empty, exiting";
    exit 3;
fi

if [ ! -n "$VALUE" ]; then
    echo "Value (0.12, 223.33, etc.) argument empty, exiting";
    exit 4;
fi

# Second precision writes for the database are more than sufficient
# for something that is monitored on a daily basis...
if [ ! -n "$DATE" ]; then
    DATEST=`date +%s`
else
    # Assuming DATE as YYY.MM.DD
    ISODATE=`echo $DATE | sed 's/\./-/g'`
    DATEST=`date --date "${ISODATE} 12:00:01" +%s`
fi

DBI=performance
DATA="${METRIC},device=${DEVICE},product=${PRODUCTID} value=${VALUE} ${DATEST}"


# v1.8
#DB="http://localhost:8086/write?db=${DBI}&precision=s"
#curl -i -XPOST "${DB}"  --data-binary "${DATA}"

# v2.0
DBHOST="hilldale-b40313e5.influxcloud.net"
DB="https://${DBHOST}:8086/api/v2/write?bucket=${DBI}&precision=s"
AUTH="Authorization: Token performance_wo:7169686c5ad9119c2557cae47919aff0"
curl -i -XPOST "${DB}" --header "${AUTH}" --data-raw "${DATA}"
