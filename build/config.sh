#!/bin/bash

# This file contains all the configuration options available to bashbuilder.sh.
# All optional features can be set to a 0 to disable and to a 1 enable.

# The only configuration necessary for the script to run is to either set REPOPATH
# to the path of a repository, or to call it with a path to the script as $1

################################################################################
# Path to the repository to run the build scripts on.                          #
# Can be overridden by $1 if a alternative temporary path is needed.           #
################################################################################
REPOPATH=""


################################################################################
# Indicates how the log created by the build scripts should by written when a  #
# build is faulty, it can be written to log file, send as a email or both.     #
#                                                                              #
# For email is the configuration of either EMAILADRESS or EXTRACTEMAILADRESS,  #
# on repositories that contain emails as author or email in the logs necessary.#
################################################################################
LOGBUILDERRORS=0
EMAILBUILDERRORS=0

################################################################################
# Configure how the system acquires names and emails for logging build errors. #
# Both can be set either statically or extracted from the latest commit, the   #
# values extracted from the logs overwrites whatever is set in config.sh.      #
#                                                                              #
# Username is written before the log message, so the owner of a commit can be  #
# identified, which makes the feature most useful if it is extracted from log. #
#                                                                              #
# Email address is target address used if EMAILBUILDERRORS is enabled, so the  #
# use of static or extracted addresses depends on who should receive the email.#
################################################################################
USERNAME="user"
EXTRACTUSERNAME=0

EMAILADRESS="email"
EXTRACTEMAILADRESS=0
