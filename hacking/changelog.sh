#!/bin/bash

curr_version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1))
prev_version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=2) | tail -1)

git log --no-merges --reverse $prev_version..$curr_version > changelog/$curr_version.txt
