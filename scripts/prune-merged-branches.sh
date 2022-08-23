#!/bin/bash

# This script will prune all branches in the local repository that have been
# merged in the remote repository.
# It will open a file with a list of branches that will be removed, allowing
# the user to review the list and decide whether to remove the branches.

git branch --merged > /tmp/merged-branches.txt && \
  vi /tmp/merged-branches.txt && \
  xargs git branch -d < /tmp/merged-branches.txt && \
  rm /tmp/merged-branches.txt
