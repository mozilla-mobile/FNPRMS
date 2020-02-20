#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Parses log files, calculates average time for the included test runs, and
# saves the result to disk.

import glob
from enum import Enum
import re
from typing import Any, Callable, List, Mapping, MutableMapping, Pattern
import os
import argparse

DisplayedLinesRe: MutableMapping[str, Pattern] = {}
DisplayedLinesStripToTime: MutableMapping[str, Pattern] = {}
DisplayedLinesRe["fenix-nightly"] = re.compile(".*ActivityManager: Fully drawn org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesRe["fenix-performance"] = re.compile(".*ActivityManager: Fully drawn org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesRe["fennec"] = re.compile(".*ActivityManager: Fully drawn org.mozilla.firefox/org.mozilla.gecko.BrowserApp.*$")

DisplayedLinesStripToTime["fenix-nightly"] = re.compile(".*ActivityManager: Fully drawn org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripToTime["fenix-performance"] = re.compile(".*ActivityManager: Fully drawn org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripToTime["fennec"] = re.compile(".*ActivityManager: Fully drawn org.mozilla.firefox/org.mozilla.gecko.BrowserApp: \+")
DisplayedLinesTime = re.compile(r"""
  (?:(\d+)s)?   # Find seconds if present and store in the first group
  (?:(\d+)ms)?  # Find milliseconds if present and store in the second group
  $
""", re.VERBOSE)
RunlogPathStripTagExtension = re.compile("-.*.log$")


def validate_product(product: str) -> bool:
  if product == "fennec" or \
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
  def __init__(self: 'Runtime', product: str, runlog_path: str):
    print("Using " + product + " as a variant!")
    self.runlog_path = runlog_path
    self.product = product

  def date(self: 'Runtime') -> str:
    result: str = os.path.basename(self.runlog_path)
    result = re.sub(RunlogPathStripTagExtension, "", result)
    return result

  def time(self: 'Runtime') -> float:
    result: float = 0.0
    with open(self.runlog_path) as stats_fd:
      displayed = Runtime.find_displayed_lines(self.product, stats_fd)

    if len(displayed) == 0:
      raise ValueError("No 'Displayed' lines found in " + self.runlog_path + ".")

    try:
      result = Runtime.calculate_average(displayed, self.product)
    except ValueError as ve:
      raise ValueError(ve)

    return result

  @staticmethod
  def calculate_average(displayed_lines: List[str], product: str) -> float:
    count: int = 0;
    total: float = 0.0;
    for l in displayed_lines:
      try:
        total += Runtime.convert_displayed_line_to_time(l, product)
      except ValueError as ve:
        raise ValueError(ve)
      count += 1

    return total/(count*1.0) 

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
    runtime: Runtime = Runtime(product, stats_filename)
    result: str = "NA"
    try:
      result = str(runtime.time())
    except ValueError as ve:
      pass
    calculations[runtime.date()] = result

  try:
    with open(result_file, "w+") as result_fd:
      result_fd.write(formatter(calculations))
  except IOError as ioerror:
    pass

if __name__=="__main__":
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

  if (not validate_product(product)):
    print("Cannot run with invalid product: " + product + ".")
  else:
    # Print results in csv format.
    calculate(input_dir, Type.HA, product,  csv_format_calculations, output_dir + "/" + "ha-results.csv")
    calculate(input_dir, Type.AL, product, csv_format_calculations, output_dir + "/" + "al-results.csv")
    calculate(input_dir, Type.HANOOB, product, csv_format_calculations, output_dir + "/" + "hanoob-results.csv")

    # Print results in json format.
    calculate(input_dir, Type.HA, product,  json_format_calculations, output_dir + "/" + "ha-results.json")
    calculate(input_dir, Type.AL, product, json_format_calculations, output_dir + "/" + "al-results.json")
    calculate(input_dir, Type.HANOOB, product, json_format_calculations, output_dir + "/" + "hanoob-results.json")
  pass
