#!/bin/bash

# Compile LaTeX documents using compile-doc.sh by Daniel Hillerstrôm, and a small home written wrapper script.

# Enable and disable optional features
# 0: Disable 
# 1: Enable 
ERRORBIB=0

# Enters the Rapport directory so the build can be initiated
cd Rapport

# Compiles all the latex files with compile-doc and saves their log files if error have happened
for FILE in $( ls *.tex );
do
	# Compiles the files and sums their error codes
    bash "compile-doc.sh" "$FILE" --debug > /dev/null 2>&1 
	let RETURNCODE=$?

	# The extension is removed as the file name is needed to select the correct log file
	FILE=${FILE%.tex}

	# If a log file is left behind by compile-doc then there where problems with compilation, but we check the error codes anyway
	if [[ $RETURNCODE -ne 0 && $(ls | grep -c $FILE.log) -ne 0 ]]
	then
		if [ $(egrep -c "Undefined control" $FILE.log) -ne 0 ] 
		then
			LOG="$LOG$FILE \n\tFailed due to a undefined control sequence\n\n"
			let ERRORS+=1
		elif [[ $(egrep -c "\citation commands" $FILE.blg) -ne 0 ]]
		then
			# We only want to add the bibtex error if the feature is enabled, the break afterwards prevents it from being added as unknown
			if [ $ERRORBIB -eq 1 ]
			then
				LOG="$LOG$FILE \n\tFailed due to missing bibtex entries in the .aux file\n\n"
				let ERRORS+=1
			fi
			break
		else
			LOG="$LOG$FILE \n\tFailed due to a unkown error\n\n"
			let ERRORS+=1
		fi
	fi
done

# The log information generated is written to the temp log file
echo $LOG > $1

# The exit code are the total sum of errors as we want to be informed about anything above zero
exit $ERRORS
