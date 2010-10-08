#!/bin/bash
#
# Script that iterates through PULSE@Parkes observation directories
# and creates pulse profile images for each file.
#
# Author: Jonathan Khoo
# Date:   08.10.10
#

PAV_BIN="/pulsar/psr/linux/bin/pav"
PAV_ARGS="-DFTp -C -g"
CONVERT_BIN="/usr/bin/convert"

for i in `\ls J*/*.F`
do
  image_filename=`echo $i | sed s/F/png/`
  image_filename_small=`echo $i | sed s/.F/_sm.png/`

  $PAV_BIN $PAV_ARGS ${image_filename}/png $i

  # White on black => black on white
  $CONVERT_BIN -negate $image_filename $image_filename

  # Create smaller image (crop + resize).
  $CONVERT_BIN -crop 600x485+125+97 $image_filename $image_filename_small
  $CONVERT_BIN -resize 240x180 +repage $image_filename_small $image_filename_small

  echo $image_filename
done
