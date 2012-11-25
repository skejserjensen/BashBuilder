# BashBuilder
BashBuilder is very small build automation system that runs your own build scripts and sends you an email if anything unexpected happends.

## Installation
1. Install bash, mail and sendmail if your distribution does not have them.
2. Copy the "/build" folder to anywhere on the system containing the git repo.
3. Configure "bashbuilder.sh" by setting the three variables in the top to your desired values.
4. Put some build scripts in the scripts directory and make them executable.
5. Enable your desired git hooks and make them run bashbuilder.sh.

## Build Scripts
The build scripts is what contains the logic about how to actually build your software, run your unit tests, compile your LaTeX document or anything else that you might want to do automatically when committing your work to the central repository. The scripts can be written in whatever language you prefer as long as the files are executable by bash and are placed in the "/build/scripts" folder.

The build script functions much like git hooks which means that the only value BashBuilder is concerned about is the scripts exit code, BashBuilder follows the same conventions as git hooks which means that if the exit code is zero then the scripts ran with success and everything else is a failure and will be reported. 

Also a file name is given to the build scripts as a command line argument, you can use this to log what part of the build that failed as BashBuilder will included it in the email as extra information. Some examples of how build scripts can be written are stored in the "/scripts" folder. 

##License
The program is license under version 3 of the GPL, and a copy of the license is bundled with the program.
