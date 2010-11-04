#!/bin/bash
#
# Script to extract the MJD, period, and period error from a file (using vap
# and pdmp). Outputs into <original file>.dat:
#   MJD: XXXXX.XX
#   Period: <period>
#   Period_Error: <period error>
#
# Author: Jonathan Khoo
# Date: 21.09.10
#

# Extract MJD using vap.
VAP_ARGS="-n -c mjd"
VAP_BIN="/pulsar/psr/linux/bin/vap"

# Don't open pgplot device.
PDMP_ARGS='-g /NULL'
PDMP_BIN="/pulsar/psr/linux/bin/pdmp"

for i in `\ls J*/*.F`
do
  echo Processing $i

  DATA_FILENAME=`echo $i | sed 's/\.F/\.dat/'`
  echo $DATA_FILENAME

  #TODO: check if data file has been made.

  $VAP_BIN $VAP_ARGS $i | awk '{printf "MJD: %s\n", $2}' > $DATA_FILENAME
  $PDMP_BIN $PDMP_ARGS $i | grep "Best BC Period" | awk '{printf("Period: %s\nPeriod_Error: %s\n", $6, $14)}' >> $DATA_FILENAME
done
