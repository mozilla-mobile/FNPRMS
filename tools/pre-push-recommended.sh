#!/usr/bin/env bash

set -e

# Check for flake8 because devs need to install it.
if [ -z "`which flake8`" ]; then
  echo "Skipping flake8: command unavailable."
else
  # we can't use . because it'll go into venv if devs use it.
  flake8 *.py tests
fi

python3 -m unittest discover tests
