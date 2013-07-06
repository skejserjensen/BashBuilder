#!/bin/bash
source ./config.sh
set -o nounset

# Setup phase functions
SetVariables()
{
    # Global variables are set here to prevent undefined behaviour
    errors=0
    
    scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    tempRoot=$scriptPath"/temporary/"
}

CreateTempDirectory()
{
    local tempDirNumber=0

    # The first directory which has yet to be used is created and set as temp directory, and the loop is terminated
    while [ true ]
    do
        tempDir="$tempRoot$tempDirNumber"
        
        if [ ! -d "$tempDir" ]
        then
            mkdir "$tempDir"
            break
        fi
            let tempDirNumber++
    done
}

ExtractBranchHead()
{
    cd $REPOPATH && git archive master | tar -x -C "$tempDir"
}

CreateLogFile()
{
    local logFileNumber=0

    while [ true ]
    do
        logFile="$tempDir/$logFileNumber"

        if [  ! -f "$logFile" ]
        then
            echo "" > $logFile
            break
        fi

        let logFileNumber++
    done
}

# Execution phase functions 
ExecuteOptionalFeatures()
{
    # Gets the email of the user who made the most recent commit
    if [ $EXTRACTEMAILADRESS -eq 1 ]
    then
        cd "$REPOPATH"
        EMAILADRESS=$(echo $(git log -n1) | grep -Po '^.*?\K(?<=<).*?(?=>)')

        # Emails should work in upper case, but they are changed to lowercase just as a precaution
        EMAILADRESS=$(echo "$EMAILADRESS" | tr '[A-Z]' '[a-z]')

    fi

    # Gets the name of the user who made the most recent commit
    if [ $EXTRACTUSERNAME -eq 1 ]
    then
        cd "$REPOPATH"
        USERNAME=$(echo $(git log -n1) | grep -Po '^.*?\K(?<=Author: ).*?(?= <)')
    fi
}

RunBuildScripts()
{
    # The log file name is saved in case on the build scripts changes the value of the variable instead of just appending text to the file
    local orgLogFile=$logFile
    emailMessage=""
    
    for file in `find $scriptPath/scripts -executable -type f` ; do
        cd $tempDir

        $file $logFile
        let result=$? 
       
        if [ ! $result -eq 0 ]  
        then
            let errors+=$result
            emailMessage=$emailMessage"Executing "${file##*/}" resulted in failure, all information about this build is shown below.\n-----\n"$(cat $logFile)"\n\n"
        fi

        # Some people might not like data on their file system getting overwritten by /dev/null, so we check if they accidentally changed the location of the log 
        if [ $orgLogFile != $logFile ]
        then
           logFile=$orgLogFile 
        fi

        # The contents of the log file is truncated so its content don't gets written more then once in the email
        cat /dev/null > $logFile
    done                                                                                                            
}


# Respond phase functions
SendEmail()
{
    if [ $errors -ne 0 ]
    then
        local subject="Build failed"
        local email="/tmp/bashbuilderemail"

        # The spinlock prevents the program from overwriting $EMAILTEXT if another instance of the program is using it
        while [ -f "$email" ]
        do
            sleep 5s
        done

        printf "Dear $USERNAME\nSome parts of the build failed, please correct these error and push a new revision.\n\n$emailMessage" > "$email"
        mail -s "$subject" "$EMAILADRESS" < "$email"

        # The temp file for the email message is removed to prevent other instances of the program from going into an infinite loop
        rm -rf $email
    fi
}

WriteLog()
{
    if [ $errors -ne 0 ]
    then
        cd "$scriptPath"
        echo "$USERNAME" "${REPOPATH##*/}" "$(date)" >> ./log
    fi
}


# Cleanup phase functions
CleanUp()
{
    rm -rf "$tempDir"
}


# The main subroutine starts here
# Setup phase
SetVariables
CreateTempDirectory
ExtractBranchHead
CreateLogFile

# Execution phase
ExecuteOptionalFeatures
RunBuildScripts

# Respond phase
SendEmail
WriteLog

# Cleanup phase
CleanUp
