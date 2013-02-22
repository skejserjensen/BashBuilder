#!/bin/bash

# The configuration below needs to be set for the script to run
REPOPATH="Path to your git repository"

USERNAME="The name to be used at the top of the emails"
EMAILADRESS="Email address to write to when problems occurs"

# Optional features can be enabled and disabled here 
# 0: Disable 
# 1: Enable 
EXTRACTUSERNAME=0       # Extract the user name to be put in the email from the latest commit
EXTRACTEMAILADRESS=0    # Extract the email address to use when any errors have happened from the latest commit


# The functions and variables used below should work properly without any changes, unless there is a bug in the system of course
# Setup phase functions
function setVariables()
{
    # Global variables are set here to prevent undefined behaviour
    ERRORS=0
    
    SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    TEMPROOT=$SCRIPTPATH"/temporary/"
}

function createTempDirectory()
{
    TEMPDIRNUMBER=0

    # The first directory which has yet to be used is created and set as temp directory, and the loop is terminated
    while [ true ]
    do
        TEMPDIR="$TEMPROOT$TEMPDIRNUMBER"
        
        if [ ! -d "$TEMPDIR" ]
        then
            mkdir "$TEMPDIR"
            break
        fi
            let TEMPDIRNUMBER++
    done
}

function extractBranchHead()
{
    cd $REPOPATH && git archive master | tar -x -C $TEMPDIR 
}

function createLogFile()
{
    LOGFILENUMBER=0

    while [ true ]
    do
        LOGFILE="$TEMPDIR/$LOGFILENUMBER"

        if [  ! -f "$LOGFILE" ]
        then
            echo "" > $LOGFILE
            break
        fi

        let LOGFILENUMBER++
    done
}

# Execution phase functions 
function executeOptionalFeatures()
{
    # Gets the email of the user who made the most recent commit
    if [ $EXTRACTEMAILADRESS -eq 1 ]
    then
        cd $REPOPATH
        EMAILADRESS=$(echo $(git log -n1) | grep -Po '^.*?\K(?<=<).*?(?=>)')

        # Emails should work in upper case, but they are changed to lowercase just as a precaution
        EMAILADRESS=$(echo $EMAILADRESS | tr '[A-Z]' '[a-z]')

    fi

    # Gets the name of the user who made the most recent commit
    if [ $EXTRACTUSERNAME -eq 1 ]
    then
        cd $REPOPATH
        USERNAME=$(echo $(git log -n1) | grep -Po '^.*?\K(?<=Author: ).*?(?= <)')
    fi
}

function runBuildScripts()
{
    # The log file name is saved in case on the build scripts changes the value of the variable instead of just appending text to the file
    ORGLOGFILE=$LOGFILE
    
    for FILE in `find $SCRIPTPATH/scripts -executable -type f` ; do
        cd $TEMPDIR

        $FILE $LOGFILE
        let RESULT=$? 
       
        if [ ! $RESULT -eq 0 ]  
        then
            let ERRORS+=$RESULT
            EMAILMESSAGE=$EMAILMESSAGE"Executing "${FILE##*/}" resulted in failure, all information about this build is shown below.\n-----\n"$(cat $LOGFILE)"\n\n"
        fi

        # Some people might not like data on their file system getting overwritten by /dev/null, so we check if they accidentally changed the location of the log 
        if [ $ORGLOGFILE != $LOGFILE ]
        then
           LOGFILE=$ORGLOGFILE 
        fi

        # The contents of the log file is truncated so its content don't gets written more then once in the email
        cat /dev/null > $LOGFILE
    done                                                                                                            
}


# Respond phase functions
function sendEmail()
{
    if [ $ERRORS -ne 0 ]
    then
        SUBJECT="Build failed"
        EMAIL="/tmp/bashbuilderemail"

        # The spinlock prevents the program from overwriting $EMAILTEXT if another instance of the program is using it
        while [ -f $EMAIL ]
        do
            sleep 5s
        done

        printf "Dear $USERNAME\nSome parts of the build failed, please correct these error and push a new revision.\n\n$EMAILMESSAGE" > $EMAIL
        mail -s "$SUBJECT" "$EMAILADRESS" < $EMAIL

        # The temp file for the email message is removed to prevent other instances of the program from going into an infinite loop
        rm -rf $EMAIL
    fi
}

function writeLog()
{
    if [ $ERRORS -ne 0 ]
    then
        cd $SCRIPTPATH
        echo "$USERNAME" "${REPOPATH##*/}" "$(date)" >> ./log
    fi
}


# Cleanup phase functions
function cleanUp()
{
    rm -rf $TEMPDIR                                           
}


# The main subroutine starts here
# Setup phase
setVariables
createTempDirectory
extractBranchHead
createLogFile

# Execution phase
executeOptionalFeatures
runBuildScripts

# Respond phase
sendEmail
writeLog

# Cleanup phase
cleanUp
