#!/usr/bin/env bash

export PYTHONPATH=$(pwd)

for scenario in l2sw ; do
  ./scenarios/${scenario}/test.py;
done
