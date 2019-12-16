#!/usr/bin/env python3
import glob
from enum import Enum
import re
from typing import List, MutableMapping
import os
import argparse

DisplayedLinesRe = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesStripToTime = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripFromTime = re.compile(" .*$")
DisplayedLinesStripMs = re.compile("([0-9]+)ms")
DisplayedLinesSubSeconds = re.compile("s")
RunlogPathStripTagExtension = re.compile("-.*.log$")

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
  def __init__(self: 'Runtime', runlog_path: str):
    self.runlog_path = runlog_path

  def date(self: 'Runtime') -> str:
    result: str = os.path.basename(self.runlog_path)
    result = re.sub(RunlogPathStripTagExtension, "", result)
    return result

  def time(self: 'Runtime') -> float:
    result: float = 0.0
    with open(self.runlog_path) as stats_fd:
      displayed = Runtime.find_displayed_lines(stats_fd)

    if len(displayed) == 0:
      raise ValueError("No 'Displayed' lines found in " + self.runlog_path + ".")

    try:
      result = Runtime.calculate_average(displayed)
    except ValueError as ve:
      raise ValueError(ve)

    return result

  @staticmethod
  def calculate_average(displayed_lines: List[str]) -> float:
    count: int = 0;
    total: float = 0.0;
    for l in displayed_lines:
      try:
        total += Runtime.convert_displayed_line_to_time(l)
      except ValueError as ve:
        raise ValueError(ve)
      count += 1

    return total/(count*1.0) 

  @staticmethod
  def find_displayed_lines(fd) -> List[str]:
    result: List[str] = []
    for l in fd:
      if DisplayedLinesRe.match(l):
        result.append(l)
    return result

  @staticmethod
  def convert_displayed_line_to_time(displayed_line) -> float:
    result: float = 0
    str_result: str = ""
    str_result = re.sub(DisplayedLinesStripToTime, "", displayed_line)
    str_result = re.sub(DisplayedLinesStripFromTime , "", str_result)
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

def calculate(dirname: str, tipe: Type, result_file: str):
  stats_filename: str = ""
  calculations: MutableMapping[str, str] = {}
  for stats_filename in glob.glob(dirname + "/*-" + str(tipe) + ".log"):
    runtime: Runtime = Runtime(stats_filename)
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

  parser = argparse.ArgumentParser(description="Calculate statistics from timing runs.")
  parser.add_argument('--input_dir', type=str, required=True)
  parser.add_argument('--output_dir', type=str, required=True)
  arguments = parser.parse_args()

  input_dir = arguments.input_dir
  output_dir = arguments.output_dir

  calculate(input_dir, Type.HA, output_dir + "/" + "ha-results.csv")
  calculate(input_dir, Type.AL, output_dir + "/" + "al-results.csv")
  calculate(input_dir, Type.HANOOB, output_dir + "/" + "hanoob-results.csv")
  pass
