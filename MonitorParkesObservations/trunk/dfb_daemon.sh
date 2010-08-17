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
#           -multi      Perform processing over multiple computers
#

DFB_SCRIPT="/u/kho018/dfb_process.sh"

function usage()
{
  echo "Usage: ./dfb_daemon.sh [option]"
  echo "  -h          Help"
  echo "  -update     Force the processing on the last-modified files"
  echo "  -multi      Perform processing over multiple computers"
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

function process_one_backend()
{
  backend_parameter=$1

  while [ 1 ]
  do
    $DFB_SCRIPT $backend_parameter $update

    sleep 2
  done
}

function process_both_backends()
{
  echo "process_both_backends"

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
}

force_update=0
multi=0
hostname=""

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
    "-multi")
    multi=1
    ;;
  esac
done

# Perform an update the first time.
if [ $force_update -eq 1 ]; then
  update="-update"
fi

# If using multiple computers, get the hostname of current one.
if [ $multi -eq 1 ]; then
  hostname=`hostname`
fi

# Determine which processing loop depending on number of computers being used.
# If there are multiple computers available:
#   lagavulin: DFB3
#   jura: DFB4
if [ $multi -eq 1 ]; then
  if [ $hostname == "lagavulin" ]; then
    process_one_backend -dfb3
  elif [ $hostname == "jura" ]; then
    process_one_backend -dfb4
  fi
else
  process_both_backends
fi
fi
