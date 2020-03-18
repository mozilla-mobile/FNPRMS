#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import argparse
import os
import re
import subprocess
import sys
import time


def quiet_call(args):
    subprocess.check_call(args, stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL)


class AdbConnection:
    def __init__(self, package_name):
        self.adb = os.environ.get('ADB', 'adb')
        self.package_name = package_name

    def _shell(self, args):
        quiet_call([self.adb, 'shell'] + args)

    def install(self, apk):
        quiet_call([self.adb, 'uninstall', self.package_name])
        try:
            quiet_call([self.adb, 'install', '-t', apk])
        except Exception:
            raise RuntimeError('Error occurred installing the APK!')

    def clear_logcat(self):
        quiet_call([self.adb, 'logcat', '--clear'])
        quiet_call([self.adb, 'logcat', '-G', '2M'])

    def write_logcat(self, out):
        subprocess.check_call([self.adb, 'logcat', '-d'], stdout=out,
                              stderr=out)

    def kill_all(self):
        self._shell(['am', 'kill-all'])

    def stop(self):
        self._shell(['am', 'force-stop', self.package_name])

    def start(self, page=None):
        if page is None:
            self._shell([
                'am', 'start-activity',
                '{}/{}'.format(self.package_name, self.home_component),
                '--ez', 'performancetest', 'true'
            ])
        else:
            self._shell([
                'am', 'start-activity',
                '-t', 'text/html', '-d', page,
                '-a', 'android.intent.action.VIEW',
                '{}/{}'.format(self.package_name, self.applink_component),
                '--ez', 'performancetest', 'true'
            ])

    def keyevent(self, event='HOME'):
        self._shell(['input', 'keyevent', event])


class FenixAdbConnection(AdbConnection):
    home_component = 'org.mozilla.fenix.HomeActivity'
    applink_component = 'org.mozilla.fenix.IntentReceiverActivity'


class FennecAdbConnection(AdbConnection):
    home_component = '.App'
    applink_component = 'org.mozilla.gecko.LauncherActivity'


def connect_adb(package_name):
    if ( re.match(r'org\.mozilla\.fenix\.?', package_name) or
         package_name == 'org.mozilla.fenix_aurora' ):
        return FenixAdbConnection(package_name)
    else:
        return FennecAdbConnection(package_name)


def report_error(error, filename):
    if filename:
        with open(filename, 'w') as f:
            print(str(error), file=f)
    else:
        print('error: {}'.format(error), file=sys.stderr)
    exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('name', help='package name')
    parser.add_argument('-I', '--install', metavar='PATH',
                        help='APK to install')
    parser.add_argument('-F', '--file', metavar='PATH',
                        help='output file for logcat results')

    exec_p = parser.add_argument_group('execution arguments')
    exec_p.add_argument('-n', '--num', type=int, default=10, metavar='N',
                        help='number of test runs (default: %(default)s)')
    exec_p.add_argument('-W', '--warmup', type=int, default=1, metavar='N',
                        help=('number of test runs to warm up with before ' +
                              'recording (default: %(default)s)'))
    exec_p.add_argument('-p', '--page', metavar='URL',
                        help='page to load for app-link')

    time_p = parser.add_argument_group('timing arguments')
    time_p.add_argument('--between-time', type=float, default=1.0, metavar='T',
                        help=('time to wait between runs, in seconds ' +
                              '(default: %(default)s)'))
    time_p.add_argument('--start-time', type=float, default=5.0, metavar='T',
                        help=('time to wait after starting process, in ' +
                              'seconds (default: %(default)s)'))
    time_p.add_argument('--finish-time', type=float, default=5.0, metavar='T',
                        help=('time to wait until killing process, in ' +
                              'seconds (default: %(default)s)'))

    args = parser.parse_args()

    adb = connect_adb(args.name)
    if args.install:
        try:
            adb.install(args.install)
        except Exception as e:
            report_error(e, args.file)

    for i in range(args.warmup):
        print('Warmup run {}/{}...'.format(i + 1, args.warmup), end='\r',
              file=sys.stderr)
        adb.stop()
        adb.start(args.page)
        time.sleep(args.start_time)
    print('Warmup complete! Starting tests...', file=sys.stderr)

    # This will clear all processes that are "safe to kill". Do this to try to
    # eliminate noise.
    adb.kill_all()
    adb.clear_logcat()

    for i in range(args.num):
        print('Test run {}/{}...'.format(i + 1, args.num), end='\r',
              file=sys.stderr)
        time.sleep(args.between_time)
        adb.start(args.page)
        time.sleep(args.start_time)
        adb.keyevent()
        time.sleep(args.finish_time)
        adb.stop()
    print('Completed {} test runs!'.format(args.num), file=sys.stderr)

    if args.file:
        with open(args.file, 'w') as f:
            adb.write_logcat(f)
