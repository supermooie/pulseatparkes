#!/bin/bash

#
# dfb3_daemon.sh: a daemon which constantly calls DFB_SCRIPT to
# process the latest files.
#
# Author: Jonathan Khoo
#
# Usage: ./dfb_daemon.sh [option]
#   option: -h          Help
#           -update     Force the processing on the last-modified files
#

DFB_SCRIPT="/u/kho018/dfb_process.sh"

function usage()
{
  echo "Usage: ./dfb_daemon.sh [option]"
  echo "  -h          Help"
  echo "  -update     Force the processing on the last-modified files"
}

# Use kill -0 <pid> to check if the DFB3 and DFB4 processes area still running.
# Return true if either one of them is running.
#        false if both of them have finished.
function both_scripts_running()
{
  dfb3_script_pid=$1
  dfb4_script_pid=$2

  kill -0 $dfb3_script_pid 2> /dev/null
  dfb3_kill_return_value=$?

  kill -0 $dfb4_script_pid 2> /dev/null
  dfb4_kill_return_value=$? 

  if [ $dfb3_kill_return_value = "1" ] && [ $dfb4_kill_return_value = "1" ]
  then
    return_value=1
  else
    return_value=0
  fi
}

force_update=0

for arg in "$@"
do
  case "$arg" in
    "-h" | "--help")
    usage
    exit
    ;;
    "-update")
    force_update=1
    ;;
  esac
done

# Perform an update the first time.
if [ $force_update -eq 1 ]; then
  update="-update"
fi

while [ 1 ]
do
  $DFB_SCRIPT -dfb3 $update
  dfb3_script_pid=$!

  $DFB_SCRIPT -dfb4 $update
  dfb4_script_pid=$!

  return_value=0

  while [ $return_value -ne "1" ]
  do
    # Poll both PIDs until they have finished.
    both_scripts_running $dfb3_script_pid $dfb4_script_pid
    sleep 2
  done

  update=""

  sleep 2
done
