#!/bin/bash

#
# backend_observation_status.sh: a script used to display the observing status of
#   PDFB3 and PDFB4.
#
# Usage:
#   backend_observation_status.sh
#
# Author: Jonathan Khoo
# Date: 04.08.10
#

function usage()
{
  echo "Usage: $0"
}

DFB3_DIRECTORY="/nfs/PKCCC3_1/"
DFB4_DIRECTORY="/nfs/PKCCC4_1/"

USERNAME="pulsar"
COMPUTER="herschel"
EPPING_DIRECTORY="/var/www/vhosts/pulseatparkes.atnf.csiro.au/htdocs/dev/"

# Print '1' if there have been files modified in /nfs/PKCCC3_1/ within the last minute, otherwise, print '0'.
# find /nfs/PKCCC3_1/ -cmin -1 | wc | awk '{if ($1 != 0) print "1"; else print "0"}'

# DFBX writes to disk every minute.

# Scp argument $1 with scp details stated above.
function copy_to_epping()
{
  CMD="scp $1 ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY}"
  $CMD 2> /dev/null
}

while [ 1 -eq 1 ]
do
  DFB3_STATUS=`find ${DFB3_DIRECTORY} -cmin -1 | wc | awk '{if ($1 != 0) print "1"; else print "0"}'`
  DFB4_STATUS=`find ${DFB4_DIRECTORY} -cmin -1 | wc | awk '{if ($1 != 0) print "1"; else print "0"}'`
  TIME=`date +'%H:%M:%S'`

  echo "${DFB3_STATUS},${DFB4_STATUS},${TIME}" > ~/dfb_status.txt
  echo "DFB3: ${DFB3_STATUS} DFB4: ${DFB4_STATUS} last updated: ${TIME}"

  copy_to_epping ~/dfb_status.txt

  sleep 30
done
