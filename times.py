#!/usr/bin/env python3
import glob
from enum import Enum
import re
from typing import List

DisplayedLinesRe = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity.*$")
DisplayedLinesStripToTime = re.compile(".*ActivityManager: Displayed org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity: \+")
DisplayedLinesStripFromTime = re.compile(" .*$")
DisplayedLinesStripMs = re.compile("ms")
DisplayedLinesSubSeconds = re.compile("s")

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

def displayed_lines(fd) -> List[str]:
  result: List[str] = []
  for l in fd:
    if DisplayedLinesRe.match(l):
      result.append(l)
  return result

def calculate_average(displayed_lines: List[str]) -> float:
  count: int = 0;
  total: float = 0.0;
  for l in displayed_lines:
    try:
      total += convert_displayed_line_to_time(l)
    except ValueError as ve:
      raise ValueError(ve)

    count += 1
  return total/(count*1.0) 

def convert_displayed_line_to_time(displayed_line) -> float:
  result: float = 0
  str_result: str = ""
  str_result = re.sub(DisplayedLinesStripToTime, "", displayed_line)
  str_result = re.sub(DisplayedLinesStripFromTime , "", str_result)
  str_result = re.sub(DisplayedLinesStripMs, "", str_result)
  str_result = re.sub(DisplayedLinesSubSeconds, ".", str_result)
  try:
    result = float(str_result) 
  except ValueError as ve:
    print("ValueError: " + str_result)
    raise ValueError(ve) 

  return result

def calculate(dirname: str, tipe: Type):
  stats_filename: str = ""
  for stats_filename in glob.glob(dirname + "/*-" + str(tipe) + ".log"):
    displayed: List[str] = []

    with open(stats_filename) as stats_fd:
      displayed = displayed_lines(stats_fd)

    if len(displayed) != 0:
      try:
        print(calculate_average(displayed))
      except ValueError as ve:
        print("Value Error!")
  pass

if __name__=="__main__":
  calculate("../run_logs/", Type.HA)
  pass
