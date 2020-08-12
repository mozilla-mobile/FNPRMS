#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Generate csv- and json-formatted files containing test results
# for all the raw test data in _log_dir_ for the Fenix product
# nightly variant.

# wrapper around signal-cli or ssmtp

SUBJECT=$1
BODY=$2

if [ ! -n "$SUBJECT" ]; then
    echo "Subject argument not supplied, exiting";
    exit 1;
fi

if [ ! -n "$BODY" ]; then
    echo "Body argument not supplied, exiting";
    exit 2;
fi

echo "$BODY" | mail -s "quint FNPRMS automation: $SUBJECT" bdekoz@mozilla.com
