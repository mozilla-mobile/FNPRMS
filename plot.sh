#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
cd ${iamhere}

. common.sh


log_dir=/home/hawkinsw/run_logs/


cwd=`pwd`
cd ${log_dir}

gnuplot ${iwashere}/${iamhere}/ha.plot > /dev/null 2>&1
gnuplot ${iwashere}/${iamhere}/al.plot > /dev/null 2>&1

#git add *.png
#git commit -m "${log_base} Graph the results."
#git push fenix-mobile master -q
cd ${cwd}

cd ${iwashere}
