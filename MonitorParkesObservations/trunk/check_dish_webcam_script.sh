#!/bin/bash

#
# Restart webcam script:
#   1. if the webcam script is not running, or
#   2. if the connection to the webcam computer has hung
#
# Author: Jonathan Khoo
# Date:   24.12.10
#

SCRIPT_NAME="dish_webcam.pl"
SCRIPT_LOCATION="/var/www/vhosts/pulseatparkes.atnf.csiro.au/scripts/kho018/"

# Produced webcam image name and location.
IMAGE_NAME="image.png"
IMAGE_LOCATION="/var/www/vhosts/pulseatparkes.atnf.csiro.au/htdocs/dev/"

pgrep -f $SCRIPT_NAME > /dev/null

# Exit status for pgrep:
#   0   One or more processes matched the criteria.
#   1   No processes matched.
#   2   Syntax error in the command line.
#   3   Fatal error: out of memory etc.

# Run the webcam script, if it's not already running.
if [ $? = 1 ]
then
  nohup ${SCRIPT_LOCATION}${SCRIPT_NAME} & > /dev/null
  exit 0
fi

IMAGE_MOD_TIME=`date -r ${IMAGE_LOCATION}${IMAGE_NAME} +%s`
NOW_TIME=`date +%s`

# The difference between the image's last-modified time and now.
TIME_DIFFERENCE=`calc $NOW_TIME - $IMAGE_MOD_TIME`

# A webcam image is produced every second. So, if the image has not been
# updated within the last minute, decree that the connection to the webcam
# server has hung (or has been lost), and restart the script.
if [ $TIME_DIFFERENCE -gt 60 ]
then
  pkill -f $SCRIPT_NAME
  nohup ${SCRIPT_LOCATION}${SCRIPT_NAME} & > /dev/null
fi

exit 0
