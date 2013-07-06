#!/bin/bash

# The configuration below needs to be set for the script to run
REPOPATH="Path to your repository"

USERNAME="The name to be used at the top of the emails"
EMAILADRESS="Email address to write to when problems occurs"

# Optional features can be enabled and disabled here 
# 0: Disable 
# 1: Enable
LOGBUILDERRORS=0        # Write the log messeage when a build script returns an error
EMAILBUILDERRORS=0      # Send a mail when a build script returns an error

EXTRACTUSERNAME=0       # Extract the user name to be put in the email from the latest commit
EXTRACTEMAILADRESS=0    # Extract the email address to use when any errors have happened from the latest commit
