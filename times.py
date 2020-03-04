#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Parses log files, calculates average time for the included test runs, and
# saves the result to disk.

import datetime
import glob
from enum import Enum
import re
from typing import Callable, List, Mapping, MutableMapping, Pattern
import os
import argparse

# NB: log lines may contain either ActivityTaskManager or ActivityManager
DisplayedLinesRe: MutableMapping[str, Pattern] = {}
DisplayedLinesStripToTime: MutableMapping[str, Pattern] = {}
DisplayedLinesRe["fenix-nightly"] = re.compile(r".*Manager: Fully drawn org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesRe["fenix-performance"] = re.compile(r".*Manager: Fully drawn org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesRe["fennec"] = re.compile(r".*Manager: Fully drawn org.mozilla.firefox/org.mozilla.gecko.BrowserApp.*$")
DisplayedLinesRe["fennec-nightly"] = re.compile(r".*Manager: Fully drawn org.mozilla.fennec_aurora/org.mozilla.fenix.HomeActivity.*$")

DisplayedLinesStripToTime["fenix-nightly"] = re.compile(r".*Manager: Fully drawn org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripToTime["fenix-performance"] = re.compile(r".*Manager: Fully drawn org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripToTime["fennec"] = re.compile(r".*Manager: Fully drawn org.mozilla.firefox/org.mozilla.gecko.BrowserApp: \+")
DisplayedLinesStripToTime["fennec-nightly"] = re.compile(r".*Manager: Fully drawn org.mozilla.fennec_aurora/org.mozilla.fenix.HomeActivity: \+")

DisplayedLinesTime = re.compile(r"""
  (?:(\d+)s)?   # Find seconds if present and store in the first group
  (?:(\d+)ms)?  # Find milliseconds if present and store in the second group
""", re.VERBOSE)
RunlogPathStripTagExtension = re.compile(r"-.*.log$")

LOGCAT_TIMESTAMP_CAPTURE_RE = '(\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3})'


def validate_product(product: str) -> bool:
  if product == "fennec" or \
     product == "fennec-nightly" or \
     product == "fenix-nightly" or \
     product == "fenix-performance":
    return True
  return False


class Type(Enum):
  HA = 1
  AL = 2
  HANOOB = 3

  def __str__(self):
    if self == Type.HA:
      return "ha"
    elif self == Type.AL:
      return "al"
    elif self == Type.HANOOB:
      return "hanoob"
    else:
      return ""


class Runtime:
  def __init__(self: 'Runtime', product: str, tipe: Type, runlog_path: str):
    print("Using " + product + " as a variant! " + runlog_path)
    self.runlog_path = runlog_path
    self.product = product
    self.tipe = tipe

  def date(self: 'Runtime') -> str:
    result: str = os.path.basename(self.runlog_path)
    result = re.sub(RunlogPathStripTagExtension, "", result)
    return result

  def time(self: 'Runtime') -> float:
    # https://github.com/mozilla-mobile/fenix/issues/8865: we had to update app link in a hurry
    # so we do our own thing. We shove the whole thing into a single method to save implementation time.
    # It only supports fennec-nightly & fennec.
    if (self.product == 'fennec-nightly' or self.product == 'fennec') and self.tipe == Type.AL:
      return Runtime.time_app_link(self)

    with open(self.runlog_path) as stats_fd:
      displayed = Runtime.find_displayed_lines(self.product, stats_fd)

    if len(displayed) == 0:
      raise ValueError("No 'Displayed' lines found in " + self.runlog_path + ".")

    return Runtime.calculate_average(displayed, self.product)

  @staticmethod
  def calculate_average(displayed_lines: List[str], product: str) -> float:
    count: int = 0
    total: float = 0.0
    for l in displayed_lines:
      try:
        total += Runtime.convert_displayed_line_to_time(l, product)
      except ValueError as ve:
        raise ValueError(ve)
      count += 1

    return total / (count * 1.0)

  @staticmethod
  def time_app_link(self: 'Runtime') -> List[str]:
    """
    Finds the lines needed to parse the duration of app link.

    For each run in Fenix, we expect the following relevant logs:
      - Intent start
      - page load stop about:blank
      - page load stop intended site (this is probably a bug)
      - page load stop intended site (we should use this one)

    For each, we use the timestamps of first and last logs to determine the duration.
    """
    #if self.product == 'Fennec'

    print_lines = True
    with open(self.runlog_path) as f:
      if self.product == 'fennec':
        durations = Runtime.get_durations_fennec(f, print_lines)
      else:
        durations = Runtime.get_durations_fenix(f, print_lines)

    return Runtime.calculate_average_app_link(durations)

  @staticmethod
  def get_durations_fenix(f, print_lines):
    """
    For each run in Fenix, we expect the following relevant logs:
      - START: Intent start
      - page load stop about:blank
      - page load stop intended site (this is probably a bug)
      - END: page load stop intended site (we should use this one)

    For each, we use the timestamps of START and END to make our calculations.
    """

    # Example: 02-28 15:45:23.895  1308  3152 I ActivityTaskManager: START u0 {act=android.intent.action.VIEW dat=https://example.com/... flg=0x10000000 cmp=org.mozilla.fenix.nightly/org.mozilla.fenix.IntentReceiverActivity} from uid 2000
    fenix_intent = re.compile(LOGCAT_TIMESTAMP_CAPTURE_RE +
        '.*Activity.*Manager: START.*org.mozilla.fennec_aurora/org.mozilla.fenix.IntentReceiverActivity')

    # Example: 02-28 15:45:03.910 D/GeckoSession( 9812): handleMessage GeckoView:PageStart uri=https://example.com/
    fenix_page_start = re.compile(LOGCAT_TIMESTAMP_CAPTURE_RE +
        '.*GeckoSession.* handleMessage GeckoView:PageStart uri=')

    # Example: 02-28 15:45:03.928 D/GeckoSession( 9812): handleMessage GeckoView:PageStop uri=null
    fenix_stop = re.compile(LOGCAT_TIMESTAMP_CAPTURE_RE +
        '.*GeckoSession.* handleMessage GeckoView:PageStop uri=null')

    # This repeats get_durations_fennec but it's quicker/easier to do this than to come up with
    # a combined solution.
    durations = []
    intent = ''
    page_start_count = 0
    for line in f:
      match = fenix_intent.match(line)
      if match:
        if intent:
          raise ValueError('found two start lines in a row')
        intent = match.group(1)
        if print_lines: print(match.group(0))
        continue

      match = fenix_page_start.match(line)
      if match:
        if not intent or page_start_count > 3:
          raise ValueError('expected START to be seen first')
        page_start_count += 1
        continue

      match = fenix_stop.match(line)
      if match and page_start_count == 3:
        if not intent:
          raise ValueError('intent was not set')
        stop = match.group(1)
        if print_lines: print(match.group(0))

        diff = Runtime.get_duration_between_timestamps(intent, stop)
        durations.append(diff)

        # reset for next match
        intent = ''
        page_start_count = 0

    print('found iteration count: ' + str(len(durations))) # sanity check.
    return durations

  @staticmethod
  def get_durations_fennec(f, print_lines):
    """
    For each run in Fennec, we expect the following relevant logs:
      - START: Intent start
      - END: page load stop

    For each, we use the timestamps of START and END to make our calculations.
    """

    # Example: 02-28 13:59:46.424  1308 12190 I ActivityTaskManager: START u0 {act=android.intent.action.VIEW dat=https://example.com/... typ=text/html flg=0x10000000 cmp=org.mozilla.firefox/org.mozilla.gecko.LauncherActivity} from uid 2000
    fennec_intent = re.compile(LOGCAT_TIMESTAMP_CAPTURE_RE +
        '.*Activity.*Manager: START.*org.mozilla.firefox/org.mozilla.gecko.LauncherActivity')

    # Example: 02-28 14:00:29.883  4497  4497 I GeckoTabs: zerdatime 975995111 - page load stop
    fennec_stop = re.compile(LOGCAT_TIMESTAMP_CAPTURE_RE +
        '.*GeckoTabs:.*page load stop$')

    # This repeats get_durations_fenix but it's quicker/easier to do this than to come up with
    # a combined solution.
    durations = []
    start = ''
    for line in f:
      match = fennec_intent.match(line)
      if match:
        if start:
          raise ValueError('found two start lines in a row')
        start = match.group(1)
        if print_lines: print(match.group(0))
        continue

      match = fennec_stop.match(line)
      if match:
        if not start:
          raise ValueError('start was not set')
        stop = match.group(1)
        if print_lines: print(match.group(0))

        diff = Runtime.get_duration_between_timestamps(start, stop)
        durations.append(diff)

        # reset for next match
        start = ''

    print('found iteration count: ' + str(len(durations))) # sanity check.
    return durations

  @staticmethod
  def calculate_average_app_link(durations):
    if len(durations) == 0:
      raise ValueError('Did not find any matching lines for variant: is the intent configured correctly?')

    float_durations = [d.total_seconds() for d in durations]
    return sum(float_durations) / len(float_durations)

  @staticmethod
  def get_duration_between_timestamps(start, stop):
    start_date = Runtime.parse_logcat_timestamp(start)
    stop_date = Runtime.parse_logcat_timestamp(stop)
    return stop_date - start_date

  @staticmethod
  def parse_logcat_timestamp(timestamp):
    # TODO: this will break across year boundaries because we cannot parse a year.

    # Example: 02-28 14:00:29.883
    #
    # strptime can't parse milliseconds, only microseconds, so we omit it.
    timestamp_no_ms = timestamp[:-4]
    date_no_ms = datetime.datetime.strptime(timestamp_no_ms, '%m-%d %H:%M:%S')

    # Add the ms back.
    date_ms = datetime.timedelta(milliseconds = int(timestamp[-3:]))
    return date_no_ms + date_ms

  @staticmethod
  def find_displayed_lines(product, fd) -> List[str]:
    result: List[str] = []
    for l in fd:
      if DisplayedLinesRe[product].match(l):
        result.append(l)
    return result

  @staticmethod
  def convert_displayed_line_to_time(displayed_line: str, product: str) -> float:
    str_result: str = ""
    str_result = re.sub(DisplayedLinesStripToTime[product], "", displayed_line)
    m = re.search(DisplayedLinesTime, str_result)
    if m.group(1) is None and m.group(2) is None:
      raise ValueError('unable to convert line to time')
    return float(m.group(1) or 0) + float(m.group(2) or 0) / 1000


def csv_format_calculations(calculations: Mapping[str, str]) -> str:
  result: str = ""
  for date in sorted(calculations.keys()):
    result += date + ", " + calculations[date] + "\n"
  return result


def json_format_calculations(calculations: Mapping[str, str]) -> str:
  result: str = ""
  firstresult: bool = True
  result = "["
  for key in sorted(calculations.keys()):
    if firstresult:
      firstresult = False
    else:
      result += ","

    value: str = calculations[key] if calculations[key] != "NA" else "0"
    date: str = key.replace(".", "-")

    result += "\n{ \"date\": \"" + date + "\", \"value\": " + value + "}"

  result += "\n]"
  return result


def calculate(dirname: str, tipe: Type, product: str, formatter: Callable[[Mapping[str, str]], str], result_file: str):
  stats_filename: str = ""
  calculations: MutableMapping[str, str] = {}
  for stats_filename in glob.glob(dirname + "/*-" + str(tipe) + ".log"):
    date_num = re.sub('[^0-9]','', stats_filename)
    runtime : Runtime

    # We only started to use `fennec-nightly` builds after this date.
    is_fennec_nightly_available = int(date_num) >= 20200224
    if not is_fennec_nightly_available:
        runtime = Runtime("fenix-nightly", tipe, stats_filename)
    else:
        runtime = Runtime(product, tipe, stats_filename)
    result: str = "NA"
    try:
      result = str(runtime.time())
    except ValueError:
      pass
    calculations[runtime.date()] = result

  try:
    with open(result_file, "w+") as result_fd:
      result_fd.write(formatter(calculations))
  except IOError:
    pass


if __name__ == "__main__":
  input_dir: str = ""
  output_dir: str = ""
  product: str = ""

  parser = argparse.ArgumentParser(description="Calculate statistics from timing runs.")
  parser.add_argument('--input_dir', type=str, required=True)
  parser.add_argument('--output_dir', type=str, required=True)
  parser.add_argument('--product', type=str, required=True)
  arguments = parser.parse_args()

  input_dir = arguments.input_dir
  output_dir = arguments.output_dir
  product = arguments.product

  # This variant is added on the TOR machine to make common_products.sh work
  # with a separate armv7 URL. However, this script won't work because it hardcodes
  # support for each variant. To simplify implementation, we just transform the variant
  # into the appropriate supported one.
  if product == 'fennec-nightly-g5':
    product = 'fennec-nightly'

  if (not validate_product(product)):
    print("Cannot run with invalid product: " + product + ".")
  else:
    # Print results in csv format.
    calculate(input_dir, Type.HA, product, csv_format_calculations, output_dir + "/" + "ha-results.csv")
    calculate(input_dir, Type.AL, product, csv_format_calculations, output_dir + "/" + "al-results.csv")
    calculate(input_dir, Type.HANOOB, product, csv_format_calculations, output_dir + "/" + "hanoob-results.csv")

    # Print results in json format.
    calculate(input_dir, Type.HA, product, json_format_calculations, output_dir + "/" + "ha-results.json")
    calculate(input_dir, Type.AL, product, json_format_calculations, output_dir + "/" + "al-results.json")
    calculate(input_dir, Type.HANOOB, product, json_format_calculations, output_dir + "/" + "hanoob-results.json")
  pass
