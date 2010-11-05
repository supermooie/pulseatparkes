#!/bin/bash

#
# Script to benchmark the current background DFB processing and compare it to
# a newer one.
#
# Author: Jonathan Khoo
# Date:   4.11.10
#

# files: 1.rf 2.rf 3.rf 4.rf - incremental files of an on-going observation.

# current process:
#   1. move latest file to /tmp/
#   2. pscrunch
#   3. 1. fscrunch
#      2. tscrunch

# proposed process:
#   1. if same observation, delete subints from latest file
#   2. add (pscrunched) latest file to pscrunched file
#   3. 1. add (fscrunched ) latest file to fscrunched file
#   3. 2. add (tscrunched ) latest file to tscrunched file

files=("1.rf" "2.rf" "3.rf" "4.rf")
TMP_DIR="/tmp/"

function pids_running()
{
  kill -0 $1 2> /dev/null
  pid1=$?

  kill -0 $2 2> /dev/null
  pid2=$?

  kill -0 $3 2> /dev/null
  pid3=$?

  if [ $pid1 = "1" ] && [ $pid2 = "1" ] && [ $pid3 = "1" ]
  then
    return_value=1
  else
    return_value=0
  fi
}

function current_process()
{
  for index in 0 1 2 3    # Four files
  do
    echo Current process - processing: ${files[$index]}

    filename_basename=`basename ${files[$index]} .cf`
    filename_basename=`basename $filename_basename .rf`
    pscrunch_filename=${filename_basename}.p

    echo Current process - pscrunching
    pam -u $TMP_DIR -e p -p ${files[$index]}

    echo Current process - moving
    mv -v ${TMP_DIR}${pscrunch_filename} ${TMP_DIR}/tmp.p 

    echo Current process - fscrunching 
    pam -e Fp -F ${TMP_DIR}tmp.p

    echo "Current process - fscrunching & tscrunching"
    pam -e FTp -FT ${TMP_DIR}tmp.p

    echo Current process - tscrunching 
    pam -e Tp -Tp ${TMP_DIR}tmp.p 

  done
}

function proposed_process()
{
  for index in 0 1 2 3    # Four files
  do
    echo Proposed process - processing: ${files[$index]}

    if [ $index -eq 0 ]; then
      filename_basename=`basename ${files[$index]} .cf`
      filename_basename=`basename $filename_basename .rf`
      pscrunch_filename=${filename_basename}.p

      pam -u $TMP_DIR -e p -p ${files[$index]}

      echo Current process - moving
      mv -v ${TMP_DIR}${pscrunch_filename} ${TMP_DIR}/tmp.p 

      echo Current process - fscrunching 
      pam -e Fp -F ${TMP_DIR}tmp.p

      echo "Current process - fscrunching & tscrunching"
      pam -e FTp -FT ${TMP_DIR}tmp.p

      echo Current process - tscrunching 
      pam -e Tp -Tp ${TMP_DIR}tmp.p 
    else
      current_subints=`vap -nc nsub ${files[$index]} | awk '{print $2}'`
      previous_subints=`vap -nc nsub ${TMP_DIR}/tmp.p | awk '{print $2}'`

      let "subints_index=$current_subints-$previous_subints-1"

      paz -e paz -O $TMP_DIR ${files[$index]}
    fi
  done
}

if [ $# -ne 1 ]; then
  echo "$0 [1|2] (current|proposed)"
  exit
fi

if [ $1 = "1" ]; then
  current_process
elif [ $1 = "2" ]; then
  proposed_process
else
  echo "$0 [1|2] (current|proposed)"
  exit
fi
