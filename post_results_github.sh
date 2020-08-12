#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Generate csv- and json-formatted files containing test results
# for all the raw test data in _log_dir_ for the Fenix product
# nightly variant.

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

. common.sh

cwd=`pwd`

echo "${test_date}"
echo "using results in directory: ${fpm_results_dir}"

cd ${fpm_results_dir}
git add *.csv
git add *.json
git commit -m "${test_date} update stats"
git push -q

cd ${cwd}
