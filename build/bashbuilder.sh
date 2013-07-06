#!/bin/bash
source ./config.sh

# Setup phase functions
SetVariables()
{
    # Ensures BashBuilder know where to write the log files if errors occurs
    scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    tempRoot=$scriptPath"/temporary/"

    # Checks if the user have provided the path to the repository from the hook
    if [ -d "$1" ]
    then
        REPOPATH="$1"
    elif [ ! -d "$REPOPATH" ]
    then
        WriteErrorLog "neither hook nor config.sh provided a working path"
        exit 1
    fi


    # Extraction of the repository name requires that the path does not end with /
    if [[ "$REPOPATH" == */ ]]
    then
        REPOPATH=${REPOPATH%?}
    fi

    # Checks what version control system is used
    # 0: subversion, 1: git, 2: mercurial
    versionControlSystem=""
    if [ -f "$REPOPATH""/format" ]
    then
        versionControlSystem=0
   elif [ -f "$REPOPATH""/HEAD" ]
   then
        versionControlSystem=1
   elif [ -d "$REPOPATH""/.hg" ]
   then
        versionControlSystem=2
   else
       WriteErrorLog "repopath is not set to a suported version control repository"
       exit 1
    fi
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
    case $versionControlSystem in
        0)
            cd "$tempDir" && svn checkout "file://""$REPOPATH" .;;
        1)
            cd "$REPOPATH" && git archive master | tar -x -C "$tempDir";;
        2)
            cd "$REPOPATH" && hg archive -p . "$tempDir""/data.tar"
            cd "$tempDir" && tar xf ./data.tar && rm -rf ./data.tar
            ;;
    esac
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
    let errors=0
    message=""
    
    for file in `find $scriptPath/scripts -executable -type f` ; do
        cd $tempDir

        $file $logFile
        let result=$? 
       
        if [ ! $result -eq 0 ]  
        then
            let errors+=$result
            message=$message"Executing "${file##*/}" resulted in failure, all information about this build is shown below.\n-----\n"$(cat $logFile)"\n\n"
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
    if [ $EMAILBUILDERRORS -eq 1 ]
    then
        if [ $errors -ne 0 ]
        then
            if  type -p mail > /dev/null;
            then
                local subject="Build failed"
                local email="/tmp/bashbuilderemail"

                # The spinlock prevents the program from overwriting $email if another instance of the program is using it
                local let emailSuffix=0
                while [ -f "$email" ]
                do
                    email="$email""$emailSuffix"
                    let emailSuffix++
                done

                printf "Dear $USERNAME\nSome parts of the build failed, please correct these error and push a new revision.\n\n$message" > "$email"
                mail -s "$subject" "$EMAILADRESS" < "$email"

                # The temp file for the email message is removed to prevent other instances of the program from going into an infinite loop
                rm -rf $email
            else
                WriteErrorLog "mail is not located in path, email with build errors could not be send"
                exit 1
            fi
        fi
    fi
}

WriteBuildLog()
{
    if [ $errors -ne 0 ]
    then
        cd "$scriptPath"
        echo -e "[Date: $(date)""    Repository: ${REPOPATH##*/}""    User: $USERNAME]" >> ./build.log

        if [ $LOGBUILDERRORS -eq 1 ] 
        then 
            echo -e "$message" >> ./build.log
        fi
    fi
}

WriteErrorLog()
{
    if [ "$1" != "" ]
    then
        cd "$scriptPath"
        echo -e "[Date: $(date)""    Repository: ${REPOPATH##*/}]\n""    Messeage: $1" >> ./error.log
    fi
}


# Cleanup phase functions
CleanUp()
{
    rm -rf "$tempDir"
}


# The main subroutine starts here
argumentPath="$1"
set -o nounset

# Setup phase
SetVariables "$argumentPath" #The user could have provided the path to the repository from the hook
CreateTempDirectory
ExtractBranchHead
CreateLogFile

# Execution phase
ExecuteOptionalFeatures
RunBuildScripts

# Respond phase
SendEmail
WriteBuildLog

# Cleanup phase
CleanUp
