#!/usr/bin/env bash

# Use lintstack.py to compare pylint errors.
# We run pylint twice, once on HEAD, once on the code before the latest
# commit for review.
set -e
TOOLS_DIR=$(cd $(dirname "$0") && pwd)
# Get the current branch name.
GITHEAD=`git rev-parse --abbrev-ref HEAD`
if [[ "$GITHEAD" == "HEAD" ]]; then
    # In detached head mode, get revision number instead
    GITHEAD=`git rev-parse HEAD`
    echo "Currently we are at commit $GITHEAD"
else
    echo "Currently we are at branch $GITHEAD"
fi

cp -f $TOOLS_DIR/lintstack.py $TOOLS_DIR/lintstack.head.py

if git rev-parse HEAD^2 2>/dev/null; then
    # The HEAD is a Merge commit. Here, the patch to review is
    # HEAD^2, the master branch is at HEAD^1, and the patch was
    # written based on HEAD^2~1.
    PREV_COMMIT=`git rev-parse HEAD^2~1`
    git checkout HEAD~1
    # The git merge is necessary for reviews with a series of patches.
    # If not, this is a no-op so won't hurt either.
    git merge $PREV_COMMIT
else
    # The HEAD is not a merge commit. This won't happen on gerrit.
    # Most likely you are running against your own patch locally.
    # We assume the patch to examine is HEAD, and we compare it against
    # HEAD~1
    git checkout HEAD~1
fi

# First generate tools/pylint_exceptions from HEAD~1
$TOOLS_DIR/lintstack.head.py generate
# Then use that as a reference to compare against HEAD
git checkout $GITHEAD
$TOOLS_DIR/lintstack.head.py
echo "Check passed. FYI: the pylint exceptions are:"
cat $TOOLS_DIR/pylint_exceptions

