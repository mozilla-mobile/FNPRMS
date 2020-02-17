# Fenix Nightly Performance Regression Monitoring System
Scripts to automatically test the startup performance of Fenix's
nightly variant of Fenix *or* manually test the startup performance of
Fennec or Fenix.

## Operation:
To use the system automatically, see `test.sh`, `do_times.sh` and `plot.sh`. To
operate the system manually, see `manual_test.sh`, `manual_do_times.sh` and
`plot.sh`.

## Installation

### Pre-run Customization:
1. `common.sh`:
- `ADB`: Change to the location of `adb` on the system.

For tests run under automation:
1. `test.sh`:
- `log_dir`: Change to the location to store test output logs.
1. `do_times.sh`:
- `log_dir`: Change to the location where test output logs can be found. This value should match `log_dir` specified in `test.sh`.

For tests run manaully:
1. `manual_test.sh`:
- `log_dir`: Change to the location to store test output logs.
1. `manual_dotimes.sh`:
- `log_dir`: Change to the location where test output logs can be found. This value should match `log_dir` specified in `manual_test.sh`.

## LICENSE

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/
