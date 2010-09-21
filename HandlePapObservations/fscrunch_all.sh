#!/bin/bash
#
# Script that iterates through PULSE@Parkes observation directories
# and fully fscrunches each file.
#
# Author: Jonathan Khoo
# Date: 21.09.10
#

PAM_BIN="/pulsar/psr/linux/bin/pam"

# Fully fscrunch; use 'F' as extension.
PAM_ARGS="-e F -F"

for i in `\ls J*/*.rf`
do
  fscrunched_filename=`echo $i | sed s/rf/F/`

  if [ ! -f $fscrunched_filename ]; then
    # Create fscrunched file if it hasn't already been made.

    # TODO: add option to force creation.
    $PAM_BIN $PAM_ARGS $i
  fi
done
