#!/usr/bin/env python3
import glob
from enum import Enum
import re
from typing import Pattern, List, MutableMapping
import os
import argparse

DisplayedLinesRe: MutableMapping[str, Pattern] = {}
DisplayedLinesStripToTime: MutableMapping[str, Pattern] = {}
DisplayedLinesRe["fenix-nightly"] = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesRe["fenix-performancetest"] = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesRe["fennec"] = re.compile(".*ActivityManager: Displayed org.mozilla.firefox/org.mozilla.gecko.BrowserApp.*$")

DisplayedLinesStripToTime["fenix-nightly"] = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripToTime["fenix-performancetest"] = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripToTime["fennec"] = re.compile(".*ActivityManager: Displayed org.mozilla.firefox/org.mozilla.gecko.BrowserApp: \+")

DisplayedLinesStripFromTime = re.compile(" .*$")
DisplayedLinesStripMs = re.compile("([0-9]+)ms")
DisplayedLinesSubSeconds = re.compile("s")
RunlogPathStripTagExtension = re.compile("-.*.log$")

class Type(Enum):
  HA = 1
  AL = 2

  def __str__(self):
    if self == Type.HA:
      return "ha"
    elif self == Type.AL:
      return "al"
    else:
      return ""

class Runtime:
  def __init__(self: 'Runtime', variant: str, runlog_path: str):
    print("Using " + variant + " as a variant!")
    self.runlog_path = runlog_path
    self.variant = variant

  def date(self: 'Runtime') -> str:
    result: str = os.path.basename(self.runlog_path)
    result = re.sub(RunlogPathStripTagExtension, "", result)
    return result

  def time(self: 'Runtime') -> float:
    result: float = 0.0
    with open(self.runlog_path) as stats_fd:
      displayed = Runtime.find_displayed_lines(self.variant, stats_fd)

    if len(displayed) == 0:
      raise ValueError("No 'Displayed' lines found in " + self.runlog_path + ".")

    try:
      result = Runtime.calculate_average(displayed, self.variant)
    except ValueError as ve:
      raise ValueError(ve)

    return result

  @staticmethod
  def calculate_average(displayed_lines: List[str], variant: str) -> float:
    count: int = 0;
    total: float = 0.0;
    for l in displayed_lines:
      try:
        total += Runtime.convert_displayed_line_to_time(l, variant)
      except ValueError as ve:
        raise ValueError(ve)
      count += 1

    return total/(count*1.0) 

  @staticmethod
  def find_displayed_lines(variant, fd) -> List[str]:
    result: List[str] = []
    for l in fd:
      if DisplayedLinesRe[variant].match(l):
        result.append(l)
    return result

  @staticmethod
  def convert_displayed_line_to_time(displayed_line: str, variant: str) -> float:
    result: float = 0
    str_result: str = ""
    str_result = re.sub(DisplayedLinesStripToTime[variant], "", displayed_line)
    str_result = re.sub(DisplayedLinesStripFromTime, "", str_result)
    str_result = re.sub(DisplayedLinesStripMs, ".\\1", str_result)
    str_result = re.sub(DisplayedLinesSubSeconds, "", str_result)
    try:
      result = float(str_result) 
    except ValueError as ve:
      raise ValueError(ve) 

    return result

def format_calculations(calculations) -> str:
  result: str = ""
  for date in sorted(calculations.keys()):
    result += date + ", " + calculations[date] + "\n"
  return result

def calculate(dirname: str, tipe: Type, variant: str, result_file: str):
  stats_filename: str = ""
  calculations: MutableMapping[str, str] = {}
  for stats_filename in glob.glob(dirname + "/*-" + str(tipe) + ".log"):
    runtime: Runtime = Runtime(variant, stats_filename)
    result: str = "NA"
    try:
      result = str(runtime.time())
    except ValueError as ve:
      pass
    calculations[runtime.date()] = result

  try:
    with open(result_file, "w+") as result_fd:
      result_fd.write(format_calculations(calculations))
  except IOError as ioerror:
    pass

if __name__=="__main__":
  input_dir: str = ""
  output_dir: str = ""
  variant: str = ""

  parser = argparse.ArgumentParser(description="Calculate statistics from timing runs.")
  parser.add_argument('--input_dir', type=str, required=True)
  parser.add_argument('--output_dir', type=str, required=True)
  parser.add_argument('--variant', type=str, required=True)
  arguments = parser.parse_args()

  input_dir = arguments.input_dir
  output_dir = arguments.output_dir
  variant = arguments.variant

  calculate(input_dir, Type.HA, variant, output_dir + "/" + "ha-results.csv")
  calculate(input_dir, Type.AL, variant, output_dir + "/" + "al-results.csv")
  pass
