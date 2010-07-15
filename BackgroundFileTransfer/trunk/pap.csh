#!/bin/csh -f

# Background script that must be run from 'lagavulin' using the 'pulsar' user
# account.  ^C to terminate
#
# Usage: pap.csh [session number]
#
# Author: Jonathan Khoo

if ($#argv == 0) then
	echo "Usage: pap.csh [session number]"
	exit 1
else
	set sessNum = $argv[1]
	echo "--- Starting PULSE@Parkes obsveration ---"
	echo "--- session number: $sessNum ---"
endif

onintr finished

set DFB2_DIR = "/nfs/PKCCC2_1/"
set DFB3_DIR = "/nfs/PKCCC3_1/"
set DFB4_DIR = "/nfs/PKCCC4_1/"

# MAKE SURE THIS CORRESPONDS TO THE BACKEND BEING USED!!!
set obsDir = $DFB3_DIR

set findResult = ""
@ observing = 0
set oldfilename = ""

while (1 == 1)
    set result = `ls -lrt $obsDir | tail -1 | awk '{print $5 " " $9}'` 
    set filesize = `echo $result | awk '{print $1}'`
    set filename = `echo $result | awk '{print $2}'`

	set findResult = `find /nfs/$obsDir/$filename -cmin -1 | awk '{if ($0) {print "1"}}'`

	if ($findResult == 1 && $filename == $oldfilename) then
		echo "filename: $filename"
		set result = `echo $filesize | awk '{if ($1 <= 63360) {print "1"} else {print "0"}}'`

		if ($result == 1) then
			echo "--- Only header written ---"
		else
			@ observing = 1
			set psrName = `vap -c "name" $obsDir/$filename | tail -1 | awk '{print $2}'`
			echo "psrname: $psrName"

			echo "running pav"
			pav -DFTCpg "currentObs.gif/gif" --ch 1.5 $obsDir/$filename
			echo "done pav"
			/usr/bin/convert -negate -resize 400x400 currentObs.gif out.gif
      #/usr/local/karma/bin/convert -negate -resize 400x400 currentObs.gif out.gif

			echo "--- Copying file to Epping ---"
			scp out.gif atlas:/nfs/wwwresearch/pulsar/pulseATpks/currentObs.gif
			echo $psrName >! currentPSR
			scp currentPSR atlas:/nfs/wwwresearch/pulsar/pulseATpks/.

			echo "--- Done stuff - sleeping (5 secs) ---"
		endif

		sleep 5

	else
		if ($observing == 1) then
			echo "---+++ Finished observation +++---"
			@ observing = 0

			if (`grep -i $psrName pap_pulsars | wc -l` == 1) then
				echo "--- This is a PULSE@Parkes pulsar... doing stuff ---"
				@ obNum = `grep -i "$psrName*.$sessNum" logFile | tail -n 1 | awk '{if ($0) {print $3}}'`
				@ obNum++
				echo "$psrName $sessNum $obNum" >> logFile
				./finishObs $obsDir/$filename $sessNum $obNum
			else
				echo "--- Not a PULSE@Parkes pulsar ---"
			endif
		else
			echo "--- Not observing --- sleeping (30 secs)"
		endif

		sleep 30
	endif
	set oldfilename = $filename
end

finished:
echo "*** Observing's finished - terminating script ***"
exit 0

