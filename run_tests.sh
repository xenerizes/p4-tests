#!/usr/bin/env bash

for scenario in l2sw ; do
  ./scenarios/${scenario}/test.py;
done
