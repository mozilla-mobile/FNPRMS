#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# NB: ordered before common.sh script is invoked
# muti-product setup, pass in string for product desired
# product strings: fennec, fennec-nightly, fenix-nightly, fenix-performance
PRODUCTID=$1

APPLINK_URL="https://example.com"

# Define "parameters" needed to execute all the tests. These names should
# be self explanatory. See README.md for customization information.
#
# fenix-nightly and fennec-nightly launch to different activities when you
# hit the homescreen icon so the discrepancy is intentional.
#
# When they print logs, they both display "Fully drawn...HomeActivity" though
# because this is ultimately the final activity displayed.
fenix_homeactivity_start_command='am start-activity org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity'
fenix_applink_start_command="am start-activity -t 'text/html' -d "$APPLINK_URL" -a android.intent.action.VIEW org.mozilla.fenix.nightly/org.mozilla.fenix.IntentReceiverActivity"
fenix_url_template="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.mobile.fenix.v2.nightly.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"

fennec_homeactivity_start_command='am start-activity org.mozilla.fennec_aurora/.App'
fennec_applink_start_command="am start-activity -t 'text/html' -d "$APPLINK_URL" -a android.intent.action.VIEW org.mozilla.fennec_aurora/org.mozilla.fenix.IntentReceiverActivity"
fennec_url_template="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.mobile.fenix.v2.fennec-nightly.DATE.latest/artifacts/public/build/arm64-v8a/geckoNightly/target.apk"

fennec_url_template_g5="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.mobile.fenix.v2.fennec-nightly.DATE.latest/artifacts/public/build/armeabi-v7a/geckoNightly/target.apk"

export fpm_product=$PRODUCTID

if [ "$PRODUCTID" = "fennec-nightly" ]; then
    export apk_package=org.mozilla.fennec_aurora
    export apk_url_template=$fennec_url_template
    export applink_start_command=$fennec_applink_start_command
    export homeactivity_start_command=$fennec_homeactivity_start_command
fi

if [ "$PRODUCTID" = "fenix-nightly" ]; then
    export apk_package=org.mozilla.fenix.nightly
    export apk_url_template=$fenix_url_template
    export applink_start_command=$fenix_applink_start_command
    export homeactivity_start_command=$fenix_homeactivity_start_command
fi

if [ "$PRODUCTID" = "fennec-nightly-g5" ]; then
    export apk_package=org.mozilla.fennec_aurora
    export apk_url_template=$fennec_url_template_g5
    export applink_start_command=$fennec_applink_start_command
    export homeactivity_start_command=$fennec_homeactivity_start_command
fi

# Report results
echo  "product is: $PRODUCTID"
echo  "package is: ${apk_package}"
