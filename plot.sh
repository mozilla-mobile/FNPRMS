#!/usr/bin/env bash

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

log_dir=/home/hawkinsw/run_logs/

cwd=`pwd`
cd ${log_dir}

gnuplot ${iamhere}/ha.plot 
gnuplot ${iamhere}/al.plot
gnuplot ${iamhere}/hanoob.plot

git add *.png
git commit -m "${log_base} Graph the results."
git push fenix-mobile master -q
cd ${cwd}

cd ${iwashere}
