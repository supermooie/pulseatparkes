#!/bin/bash

#
# dfb_process.sh: a script which produces a plot for either search-mode or fold-mode data.
#
# Usage:
#   dfb_process.sh [option]
#       -dfb3       Process DFB3 data
#       -dfb4       Process DFB4 data
#       -update     Forces processing on the last file
#
# Author: Jonathan Khoo
#

function usage()
{
  echo "Usage: $0"
  echo " * Must be run from the 'pulsar' user account."
  echo " * Must be run from lagavulin."
}


# Dummy folders for testing.
#DFB3_DIRECTORY="/psr1/pulseATpks/"
#DFB4_DIRECTORY="/psr1/pulseATpks/"

DFB3_DIRECTORY="/nfs/PKCCC3_1/"
DFB4_DIRECTORY="/nfs/PKCCC4_1/"
DIRECTORY="" # Must set to DFB3_DIRECTORY or DFB4_DIRECTORY

FOLD_MODE_HEADER_SIZE=63360
SEARCH_MODE_HEADER_SIZE=31204

USERNAME="pulsar"
COMPUTER="herschel"
EPPING_DIRECTORY="/var/www/vhosts/pulseatparkes.atnf.csiro.au/htdocs/dev/"

# Temporary directory for the pre-processed archives.
TMP_DIR="/tmp/"

# Scp argument $1 with scp details stated above.
function copy_to_epping()
{
  CMD="scp $1 ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY}"
  $CMD 2> /dev/null
}

#DIMENSIONS="300x250"
DIMENSIONS="240x180"

# Resizes image to above dimensions.
#   $1 = input file
#   $2 = output file
function resize_image()
{
  TEMP_FILENAME=`basename $1`

  CMD="/usr/bin/convert -crop 600x485+125+97 $1 /tmp/${TEMP_FILENAME}"
  $CMD

  CMD="/usr/bin/convert -resize $DIMENSIONS +repage /tmp/${TEMP_FILENAME} $2"
  $CMD
}

# Accepts 3 pids
# Sets return_value to: 0 if there are pids still running.
#                       1 if there all pids have finished.
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


# Create all 3 plots, reduce in resolution, and copy to publicly accessible folder
# on herschel.
#
# TODO: check for greeaaeaaat successes (file creation)
function fold()
{
  file=$1 # File that will be processed and plotted.
  #echo "$backend: $file"

  #filesize=`ls -la ${DIRECTORY}${file} | awk '{print $5}'`

  # check DFB status to see if processing should be done
  status_file_content=`cat ~/dfb_status.txt`

  # Format: <DFB3 status>,<DFB4 status>,time
  #   1 = observing
  #   0 = not observing

  # Remove the date.
  dfb_status=${status_file_content%,*}

  if [ $backend = "dfb3" ]; then
    dfb_status=${dfb_status%,*}
  elif [ $backend = "dfb4" ]; then
    dfb_status=${dfb_status#*,}
  fi

  if [ $dfb_status -eq 0 ]; then
    exit
  fi

  #filesize=`stat -c %s ${DIRECTORY}${file}`
  #if [ $filesize -lt $FOLD_MODE_HEADER_SIZE ]; then
    #echo "filesize: $filesize < header size: $FOLD_MODE_HEADER_SIZE"
    #exit
  #fi

  # pscrunch
  pam -u $TMP_DIR -e p -p ${DIRECTORY}${file} &> /dev/null

  filename_basename=`basename ${DIRECTORY}${file} .cf`
  filename_basename=`basename $filename_basename .rf`
  pscrunch_filename=${filename_basename}.p

  #############################
  # 1 Create pre-processed files
  #############################

  # Move pscrunched file to tmp.p
  mv ${TMP_DIR}${pscrunch_filename} ${TMP_DIR}/tmp.p

  # Create fscrunched file from tmp.p
  pam -e Fp -F ${TMP_DIR}tmp.p &> /dev/null &
  pam1_pid=$!

  # Create fscrunched, tscrunch file from tmp.p
  pam -e FTp -FT ${TMP_DIR}tmp.p &> /dev/null &
  pam2_pid=$!

  # Create tscrunched file from tmp.p
  pam -e Tp -Tp ${TMP_DIR}tmp.p &> /dev/null &
  pam3_pid=$!

  return_value=0
  while [ $return_value -ne "1" ]
  do
    # Poll both PIDs until they have finished.
    pids_running $pam1_pid $pam2_pid $pam3_pid
    sleep 1
  done

  #############################
  # 2. Create plots using pav
  #############################

  pav -DFTp -C -g ~/big-${backend}_fold_stokes.gif/gif ${TMP_DIR}tmp.FTp &
  pav1_pid=$!

  pav -YFp -C -g ~/big-${backend}_fold_time.gif/gif ${TMP_DIR}tmp.Fp &
  pav2_pid=$!

  pav -GTp -C -g ~/big-${backend}_fold_freq.gif/gif ${TMP_DIR}tmp.Tp &
  pav3_pid=$!

  return_value=0
  while [ $return_value -ne "1" ]
  do
    # Poll both PIDs until they have finished.
    pids_running $pav1_pid $pav2_pid $pav3_pid
    sleep 1
  done

  resize_image ~/big-${backend}_fold_stokes.gif ~/${backend}_fold_stokes.gif
  resize_image ~/big-${backend}_fold_time.gif ~/${backend}_fold_time.gif
  resize_image ~/big-${backend}_fold_freq.gif ~/${backend}_fold_freq.gif

  scp ~/${backend}_fold_stokes.gif ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY} 2> /dev/null &
  scp1_pid=$!

  scp ~/${backend}_fold_time.gif ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY} 2> /dev/null &
  scp2_pid=$!

  scp ~/${backend}_fold_freq.gif ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY} 2> /dev/null &
  scp2_pid=$!

  return_value=0
  while [ $return_value -ne "1" ]
  do
    # Poll both PIDs until they have finished.
    pids_running $scp1_pid $scp2_pid $scp3_pid
    sleep 1
  done

  scp ~/big-${backend}_fold_stokes.gif ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY} &> /dev/null &
  scp1_pid=$!

  scp ~/big-${backend}_fold_time.gif ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY} &> /dev/null &
  scp2_pid=$!

  scp ~/big-${backend}_fold_freq.gif ${USERNAME}@${COMPUTER}:${EPPING_DIRECTORY} &> /dev/null &
  scp2_pid=$!

  return_value=0
  while [ $return_value -ne "1" ]
  do
    # Poll both PIDs until they have finished.
    pids_running $scp1_pid $scp2_pid $scp3_pid
    sleep 1
  done

  /u/kho018/extract_observation_data.sh ${DIRECTORY}${file} ~/${backend}_fold.dat
  copy_to_epping ~/${backend}_fold.dat
}

function create_search_plots()
{
  file=$1 # File that will be processed and plotted.
  echo $file

  filesize=`ls -la ${DIRECTORY}${file} | awk '{print $5}'`

  if [ $filesize -lt $SEARCH_MODE_HEADER_SIZE ]; then
    exit
  fi

  LAST_SECONDS=3

  duration=`vap -c length ${DIRECTORY}${file} | grep sf | awk '{print $2}'`
  second=`echo $duration | awk '{print $1 - 10}'`
  first=`echo $second $LAST_SECONDS | awk '{print $1 - $2}'`

  searchplot -F -g ~/big-${backend}_search_freq.gif/gif -x $first,$second ${DIRECTORY}${file}
  resize_image ~/big-${backend}_search_freq.gif ~/${backend}_search_freq.gif

  copy_to_epping ~/${backend}_search_freq.gif
  copy_to_epping ~/big-${backend}_search_freq.gif

  searchplot -H -g ~/big-${backend}_search_hist.gif/gif -x $first,$second ${DIRECTORY}${file} 2> /dev/null
  resize_image ~/big-${backend}_search_hist.gif ~/${backend}_search_hist.gif

  copy_to_epping ~/${backend}_search_hist.gif
  copy_to_epping ~/big-${backend}_search_hist.gif

  /u/kho018/extract_search_data.sh ${DIRECTORY}${file} ~/${backend}_search.dat
  copy_to_epping ~/${backend}_search.dat

  exit
}

if [ $# -gt 2 ]; then
  usage
  exit
fi

force_update=0

for arg in "$@"
do
  case "$arg" in
    "-update" )
    force_update=1
    ;;
    "-dfb3" )
    backend="dfb3"
    ;;
    "-dfb4" )
    backend="dfb4"
    ;;
  esac
done

if [ $backend = "dfb3" ]; then
  DIRECTORY=$DFB3_DIRECTORY
elif [ $backend = "dfb4" ]; then
  DIRECTORY=$DFB4_DIRECTORY
else
  echo "INCORRECT INPUT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

# Get the latest file in PDFB3 directory.
#last_file=`ls -lrt $DIRECTORY | tail -1 | awk '{print $9}'`
last_file=`ls -rt $DIRECTORY | tail -1`
last_file_modified=`date -r ${DIRECTORY}${last_file} +%s`

current_time=`date +%s`
FIVE_MINUTES_IN_SECONDS=300
difference=$(($current_time - $last_file_modified))

if [ $force_update -eq 1 ] || [ $difference -lt $FIVE_MINUTES_IN_SECONDS ]
then
  echo "Processing: ${last_file}"
  file_extension=${last_file: -3}

  if [ $file_extension == ".sf" ]; then
    create_search_plots $last_file 
  elif [ $file_extension == ".rf" ]; then
    fold $last_file
  elif [ $file_extension == ".cf" ]; then
    fold $last_file
  else
    echo "Could not determine filetype."
  fi
else
  echo "$backend not observing"
fi
