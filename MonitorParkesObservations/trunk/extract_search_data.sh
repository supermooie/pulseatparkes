#!/bin/bash

# $1: psrchive filename
# $2: output filename

# Run from lagavulin

VAP_COMMAND="/psr1/linux/bin/vap -c"
VAP_OPTIONS="name,npol,nchan,nbits,length,tsamp,bw,freq,observer,projid,ra,dec,stt_time"

# name
# backend
# npol
# nchan
# length
# bw
# freq
# observer
# projid
# ra
# dec
# stt_time

if [ $# -ne 2 ]
then
  usage
  exit
fi

file=$1
output_filename=$2

CMD="$VAP_COMMAND $VAP_OPTIONS $file"
$CMD > $output_filename
