#!/bin/bash

#
# backend_observation_status.sh: a script used to display the observing status of
#   PDFB3 and PDFB4.
#
# Usage:
#   backend_observation_status.sh
#
# Author: Jonathan Khoo
# Date:   10.08.10
#

function usage()
{
  echo "Usage: $0"
}

DFB3_DIRECTORY="/nfs/PKCCC3_1/"
DFB4_DIRECTORY="/nfs/PKCCC4_1/"

USERNAME="kho018"
COMPUTER="herschel"
DATABASE_SCRIPT="/u/kho018/software/pap_database.sh"

# Hard-coded IDs (OM_backend.backend_id)
DB_DFB3_ID=1
DB_DFB4_ID=2

DB_TABLE=OM_observing_status
DB_OBSERVING_FIELD=observing
DB_BACKEND_ID_FIELD=backend_id
DB_TIME_UPDATED_FIELD=time_updated

# Print '1' if there have been files modified in /nfs/PKCCC3_1/ within the last minute, otherwise, print '0'.
# find /nfs/PKCCC3_1/ -cmin -1 | wc | awk '{if ($1 != 0) print "1"; else print "0"}'

# DFBX writes to disk every minute.

ssh -f ${USERNAME}@${COMPUTER} "${DATABASE_SCRIPT} \"show tables;\""

while [ 1 -eq 1 ]
do
  DFB3_STATUS=`find ${DFB3_DIRECTORY} -cmin -2 | wc | awk '{if ($1 != 0) print "1"; else print "0"}'`

  mysql_cmd="update ${DB_TABLE} set ${DB_OBSERVING_FIELD}=${DFB3_STATUS}, ${DB_TIME_UPDATED_FIELD}=now() where ${DB_BACKEND_ID_FIELD}=${DB_DFB3_ID};"
  ssh -f ${USERNAME}@${COMPUTER} "${DATABASE_SCRIPT} \"$mysql_cmd\""

  DFB4_STATUS=`find ${DFB4_DIRECTORY} -cmin -2 | wc | awk '{if ($1 != 0) print "1"; else print "0"}'`
  mysql_cmd="update ${DB_TABLE} set ${DB_OBSERVING_FIELD}=${DFB4_STATUS}, ${DB_TIME_UPDATED_FIELD}=now() where ${DB_BACKEND_ID_FIELD}=${DB_DFB4_ID};"
  ssh -f ${USERNAME}@${COMPUTER} "${DATABASE_SCRIPT} \"$mysql_cmd\""

  sleep 5
done
