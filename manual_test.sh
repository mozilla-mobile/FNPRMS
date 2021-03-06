#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Manually run _product_ under the _use_case_ use case where the application
# is stored in _apk_.

USAGE="usage: <apk file to test> <al|hanoob> <fennec|fennec-nightly>"

iamhere=${BASH_SOURCE%/*}
iwashere=`pwd`
iamhere=${iamhere/./${iwashere}}
cd ${iamhere}

apk_file=$1
use_case=$2

#DEVICEID=$1 # unused
PRODUCTID=$3

. common_devices.sh 1 # arg doesn't matter.
. common_products.sh $PRODUCTID
. common.sh

validate_product "$USAGE"

case $use_case in
  al)
    command=$applink_start_command
    ;;
  hanoob)
    command=$homeactivity_start_command
    ;;
  # we're not actively using ha so I excluded that option.
esac

if [ \( "X${apk_file}" == "X" \) -o \( "X${command}" == "X" \) -o \( "X${apk_package}" == "X" \) ]; then
  echo $USAGE
  exit 1
fi

echo ""
echo "--- RUNNING MANUAL TESTS"
echo "--- FENIX FENNEC-NIGHTLY INSTRUCTIONS:"
echo "- Comment out apk uninstallation & installation in run_test in common.sh."
echo "- Install APK"
echo "- Clear data (if was already installed)"
echo "- (necessary in hanoob only) Clear onboarding screen manually: finishonboarding isn't work" # --finishonboarding seems broken for manual tests
echo "- Test is not designed to measure with any open tabs, collections, or additional top sites. Test may not be accurate in this state"
echo ""

echo "--- FENNEC INSTRUCTIONS:"
echo "- Comment out apk uninstallation & installation in run_test in common.sh."
echo "- Install APK. If using hanoob, you MUST use the custom instrumented APK. See:"
echo "    https://drive.google.com/drive/folders/1tnBxlrftqkjuH9OwW3FoVfD3jv4Zt4hc"
echo "- Clear data (if was already installed)"
echo "- (necessary in hanoob only) Clear onboarding screen manually: finishonboarding isn't work" # --finishonboarding seems broken for manual tests
echo "- (hanoob) Test is not designed to measure if user has navigated to any website. Test may not be accurate in this state"
echo ""

test_date=`date +"%Y.%m.%d"`
log_base=${test_date}
run_log="${fpm_log_dir}/${log_base}.log"

maybe_create_dir ${fpm_log_dir}

maybe_create_file "${fpm_log_dir}/${log_base}-${use_case}.log"

run_test $apk_file "${fpm_log_dir}/${log_base}-${use_case}.log" "$apk_package" "$command" 25

cd ${iwashere}
