#!/bin/sh
# script from http://stackoverflow.com/questions/12133583
set -e

# Get a list of contributors ordered by number of commits
# and remove the commit count column
CONTRIBUTORS=$(git --no-pager shortlog -nse | cut -f 2-)
if [ -z "$CONTRIBUTORS" ] ; then
    echo "Contributors list was empty"
    exit 1
fi

# Display the contributors list and write it to the file
echo "$CONTRIBUTORS" | tee "$(git rev-parse --show-toplevel)/CONTRIBUTORS.rdoc" | sort
