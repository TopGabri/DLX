#!/bin/bash

# possibly remove old work folder
rm -rf work 2> /dev/null
# create work folder
mkdir work
# set env variables (setsynopsys)
source /eda/scripts/init_design_vision
# start design vision and print output in log file
design_vision -f DLX_t.scr  | tee synth.log
