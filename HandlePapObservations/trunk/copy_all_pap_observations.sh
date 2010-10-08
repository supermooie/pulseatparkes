#!/bin/bash

#
# Script that searches all DFBX folders and copies the new files to their
# corresponding folder in:
#     /nfs/wwwresearch/pulsar/pulseATpks/<pulsar name>/
# It prints a copy (update) command of all the found observation files.
#
# Usage: ./copy_all_pap_observations.sh
# Requires: 'pap_pulsars' (file containing all PULSE@Parkes pulsar names)
#
# Author: Jonathan Khoo
# Date: 02.09.10
#

# DFBX directories which map the current $DFBX environment variables.
DFB1_DIRECTORY="/pulsar/archive06/DFB/"
DFB2_DIRECTORY="/pulsar/archive12/DFB/"
DFB3_DIRECTORY="/pulsar/archive14/DFB/"
DFB4_DIRECTORY="/pulsar/archive18/DFB/"
DFB5_DIRECTORY="/pulsar/archive19/DFB/"

DFB_DIRECTORIES=($DFB1_DIRECTORY $DFB2_DIRECTORY $DFB3_DIRECTORY $DFB4_DIRECTORY $DFB5_DIRECTORY)

# Destination observing folder in the allocated PULSE@Parkes disk space.
COPY_DESTINATION="/pulsar/archive13/pulseATpks/Observations/"

PAP_PULSARS=`cat pap_pulsars`

VAP_COMMAND="/pulsar/psr/linux/bin/vap -c projid"

# [$DFB1:$DFB5]
for directory in ${DFB_DIRECTORIES[*]}
  do
  for pulsar in ${PAP_PULSARS[*]}
  do
    ${VAP_COMMAND} ${directory}/${pulsar}/*.rf | awk '{if ($2 == "P595") print "cp -u '${directory}${pulsar}'/" $1" '${COPY_DESTINATION}${pulsar}'/" $1}'
  done
done
