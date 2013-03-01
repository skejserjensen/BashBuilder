#!/bin/bash

# Compile LaTeX documents using compile-doc.sh by Daniel Hillerstrôm, and a small home written wrapper script.
# The script does not report error that happens doing the compilation, instead it commit the file that could be compiled to an external repository with a working directory

# Configuration
COMPILEDOCROOT="The folder that contains the CompileThemAll.sh script"
EXTERNALGITREPO="The path to the git repo containing a compile-doc structure"

# Ensures that the external repository actually does exist before we try to commit to it
if [[ ! -d "$EXTERNALGITREPO""/.git" && ! -d "$EXTERNALGITREPO"".git" ]];
then
    # The external repo does not exist, or does not have a working directory containing a .git directory, so we exit with a error code and write to the log
    echo "ERROR: external git repository does not exist or does not have a working directory" > $1
    exit 1
fi

# Ensures that the compile-doc folder specified exists and that CompileThemAll is contained in it
if [[ -f "$COMPILEDOCROOT""CompileThemAll.sh" || -f "$COMPILEDOCROOT""/CompileThemAll.sh" ]];
then
    # The Rapport folder contains the tex files and the compile-doc.sh script
    cd "$COMPILEDOCROOT"

    # Compiles all the latex files with compile-doc, but is discarding all debugging information and error codes as we want all pdf that possible can compile
    bash CompileThemAll.sh > /dev/null 2>&1

    # The Rapport folder should only contain pdf files that where compiled by compile-doc.sh without errors, so we just copy them all to the external repository
    mv *.pdf "$EXTERNALGITREPO"
    cd "$EXTERNALGITREPO"

    # GIT_DIR contains the path to the repository running the hook, so we need to reset it before running this commit, the value is saved so it can be restored
    gitDir="$GIT_DIR"
    unset GIT_DIR 

    # We just everything and them commits because git will not commit if no new files where copied to the repository, so we do not care if no pdf files could be compiled correctly
    git add -A
    git commit -am "Auto compiled pdf files build by BashBuilder using compile-and-commit.sh"

    # We set GIT_DIR again so that the script leaves the environment unchanged
    GIT_DIR="$gitDir"

    # Everything went as we expected so we exit with a positive error code
    exit 0
else
    # The external repo does not exist, or does not have a working directory containing a .git directory, so we exit with a error code and write to the log
    echo "ERROR: the compile-doc root specified does not contain the CompileThemAll.sh helper script, please correct the path specified or add the script" > $1
    exit 1
fi
