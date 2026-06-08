#!/bin/bash

CONFIG_FILE="./namelist.config"

string="test"

sed -i "s|ResultPath=.*|ResultPath='/albedo/work/projects/p_clidyn_work/rjuhrban/double_gyre/m100/results/spinup_online_validation_none/after_spinup_with_NN/$string/'|" "$CONFIG_FILE"