# Fenix Nightly Performance Regression Monitoring System
Scripts to automatically test the startup performance of Fenix's
nightly variant of Fenix *or* manually test the startup performance of
Fennec or Fenix.

## Usage
To use the system automatically, run:
* `test.sh` to run the test & generate logs
* `do_times.sh` to take the logs and extract timing information from them
* `plot.sh` to plot the timing information

To use the system manually, run:
* `manual_test.sh` to run the test & generate logs
* `manual_do_times.sh` to take the logs and extract timing information from them
* `plot.sh` to plot the timing information

## Installation

### Pre-run Customization:
`common_devices.sh`:
- `fpm_adb` and `ADB`: Change to the location of `adb` on the system and remove the serial parameter. e.g.
```
    -fpm_adb="/opt/fnprms/Android/Sdk/platform-tools/adb"
    -export ADB="${fpm_adb} -s ${fpm_dev_serial}"
    +fpm_adb=".../Library/Android/sdk/platform-tools/adb"
    +export ADB="${fpm_adb}"
```

`common.sh`:
- ``fpm_log_dir`: Change the location to store test output logs (default is only writable on root)

`manual_test.sh`:
- `run_test...`: lower integer run count if you don't want the test to take as long (though this may impact accuracy)

### Running manually
A typical invocation to run start to homescreen tests on Fenix's fennecNightly variant:
```
./manual_test.sh <fennec-nightly-apk> hanoob fennec-nightly && ./manual_do_times.sh fennec-nightly && cat <logs>/hanoob-results.csv
```

## LICENSE

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/
