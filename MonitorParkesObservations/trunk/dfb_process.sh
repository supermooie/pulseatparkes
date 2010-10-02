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


# Create all 3 plots, reduce in resolution, and copy to publicly accessible folder
# on herschel.
#
# TODO: check for greeaaeaaat successes (file creation)
function fold()
{
  file=$1 # File that will be processed and plotted.
  #echo "$backend: $file"

  filesize=`ls -la ${DIRECTORY}${file} | awk '{print $5}'`

  #if [ $filesize -lt $FOLD_MODE_HEADER_SIZE ]; then
    #echo "filesize: $filesize < header size: $FOLD_MODE_HEADER_SIZE"
    #exit
  #fi

  # Create stokes cylindrical plot (pav -SFT)
  pav -SFT -C -g ~/big-${backend}_fold_stokes.gif/gif ${DIRECTORY}${file}
  resize_image ~/big-${backend}_fold_stokes.gif ~/${backend}_fold_stokes.gif
  copy_to_epping ~/${backend}_fold_stokes.gif
  copy_to_epping ~/big-${backend}_fold_stokes.gif

  # Create time-vs-phase plot (pav -YFp)
  pav -YFp -C -g ~/big-${backend}_fold_time.gif/gif ${DIRECTORY}${file}
  resize_image ~/big-${backend}_fold_time.gif ~/${backend}_fold_time.gif
  copy_to_epping ~/${backend}_fold_time.gif
  copy_to_epping ~/big-${backend}_fold_time.gif

  # Create frequency-vs-phase plot (pav -GTp)
  pav -GTp -C -g ~/big-${backend}_fold_freq.gif/gif ${DIRECTORY}${file}
  resize_image ~/big-${backend}_fold_freq.gif ~/${backend}_fold_freq.gif
  copy_to_epping ~/${backend}_fold_freq.gif
  copy_to_epping ~/big-${backend}_fold_freq.gif

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
last_file=`ls -lrt $DIRECTORY | tail -1 | awk '{print $9}'`
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
