#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
cd ${iamhere}

. common.sh


log_dir=/home/hawkinsw/run_logs/

cwd=`pwd`
cd ${log_dir}

gnuplot ${iamhere}/ha.plot 
gnuplot ${iamhere}/al.plot

git add *.png
git commit -m "${log_base} Graph the results."
git push fenix-mobile master -q
cd ${cwd}

cd ${iwashere}
