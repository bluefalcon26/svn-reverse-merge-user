#!/bin/bash

# reverse-merge-user
# Version 1.0.0
# For use with SVN

# This will reverse-merge all of the specified user's commits from the local
# repository, searching back either the specified number of commits in total,
# or to the optionally provided commit ref, whichever comes first.

VERSION=1.0.0

# USAGE
function usage
{
	echo "Usage: reverse-merge-user [OPTION]... [USER]
Reverse-merge all of the specified user's commits from the local
repository, searching back either the specified number of commits in
total, or to the optionally provided commit ref, whichever comes first.
USER is, by default, the current SVN user.
Example: reverse-merge-user -r 2323 seimore

Options:
  -c [--commit] ARG				the last commit to consider
  -l [--length] ARG				the number of commits to look back
  -q [--quiet]					suppress output
  -V [--version]				display version information and exit
  -h [--help]					display this help text and exit"
}

# VERSION
function version
{
	echo "reverse-merge-user $VERSION
Copyright (C) BubbleUp, LLC
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Daniel Prejean."
}

# CONFUSED
function confused
{
	echo "Usage: reverse-merge-user [OPTION]... [USER]
Try 'reverse-merge-user --help' for more information."
}

# 0. SET ARGUMENTS

arg_commit=
arg_length=
arg_quiet=
arg_USER=
while [ -n "$1" ]; do
  case $1 in
    -c | --commit )			shift
                            arg_commit=$1
                            ;;
    -l | --length )         shift
                            arg_length=$1
                            ;;
    -q | --quiet )          shift
							arg_quiet=true
                            ;;
    -V | --version )        version
							exit
                            ;;
    -h | --help )           usage
                            exit
                            ;;
    * )                     if [ -n "$arg_USER" ]; then
								confused;
								exit 1
							else
								arg_USER=$1
							fi
  esac
  shift
done

# 1. SET SVN USER
# Default: *current svn user
if [ -n "$arg_USER" ]; then
	author=$arg_USER
else
	author="$(cat ~/.subversion/auth/svn.simple/* \
		| awk '/^K / { key=1; val=0; } /^V / { key=0; val=1; } ! /^[KV] / { if(key) { kname=$1; }
		if(val && kname == "username")
			{ print $1; val = 0; }
		}')"
fi

# 2. SET LENGTH
# Default: 100
if [ -n "$arg_length" ]; then
	length=$arg_length
else
	length=100
fi

# 3. SET COMMIT
# Default: *empty
if [ -n "$arg_commit" ]; then
	commit=$arg_commit
else
	commit=
fi

# MAIN. Iterate through the svn log and reverse-commit as appropriate.

svn log -q -l $length $PWD \
	| awk -v author=$author -F '|' '$0 ~ /^r/ && $2 == " "author" "  {
          print substr ($1, 2)
      }' | while read rev
           do
			   if [ -n "$arg_quiet" ]; then
				   svn merge -q -c -$rev $PWD
			   else
				   svn merge -c -$rev $PWD
			   fi
			   if [ "$rev" = "$commit" ]; then break; fi
           done

echo "done"
