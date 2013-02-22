# BashBuilder
BashBuilder is a very small build automation system that runs your own build scripts and sends you an email if anything unexpected happens.

## Dependencies
The following dependencies should be installed before installing BashBuilder.

+ GNU bash
+ GNU coreutils
+ GNU grep
+ mail
+ Git

The program was tested on various distributions of Linux all using the GNU versions of bash, coreutils and grep. 

Git is currently the only supported version control system, but support for both Subversion and Mercurial is planned.

## Installation
1. Install bash, grep and coreutils, most Unix like operation systems comes with pre-installed variants of these.
2. Install one of the many programs that provide the mail program for bash such as heirloom-mailx and configure it to use your preferred mail server.
3. Copy the "/build" folder to anywhere on your file system from where it can accesses the repositories it should run the build scripts on.
4. Configure bashbuilder.sh by setting the three uppercased variables in the top of the script to your desired values.
5. Put some build scripts in the scripts directory and make them executable, all non executable files in the directory is ignored.
6. Configure the hooks in your version control system so bashbuilder.sh is run automatically, a git hook is provided as example.

## Build Scripts
The build scripts is what contains the logic about how to actually build your software, run your unit tests, compile your LaTeX document or anything else that you might want to do automatically when committing your work to the central repository. The scripts can be written in whatever language you prefer as long as the files are executable by bash and are placed in the "/build/scripts" folder.

The build script functions much like git hooks which means that the only value BashBuilder is concerned about is the scripts exit code, BashBuilder follows the same conventions as git hooks which means that if the exit code is zero then the scripts ran with success and everything else is a failure and will be reported. 

Also a file name is given to the build scripts as a command line argument, you can use this file to log what part of the build that failed as BashBuilder will included it in the email as extra information. Some examples of how build scripts can be written are stored in the "/scripts" folder found in the root of the repository. 

## Todo
+ Add support for Subversion and Mercurial.
+ Make the branch extracted by BashBuilder a configurable parameter.

##License
The program is license under version 3 of the GPL, and a copy of the license is bundled with the program.
