#!/bin/bash

set -e

cd $WORKSPACE

if ! grep -a -q "\[INFO\] Cleaning up after release..." $WORKSPACE/../builds/$BUILD_NUMBER/log ; then
 echo "[POST RELEASE] this is no release build, skipping execution"
 exit 0
fi

RELEASE_BRANCH=`git branch | grep "*" | sed "s/* //"`
ORIGIN=`git config --get remote.origin.url`
TAGNAME=`git describe --abbrev=0 --candidate=1`
 
echo "[POST RELEASE] using RELEASE_BRANCH = $RELEASE_BRANCH"
echo "[POST RELEASE] using ORIGIN = $ORIGIN"
echo "[POST RELEASE] using TAGNAME = $TAGNAME"

if [[ $RELEASE_BRANCH == fatal* || $ORIGIN == fatal* || $TAGNAME == fatal* ]] ; then
 echo "[POST RELEASE] illegal variable state: [RELEASE_BRANCH=$RELEASE_BRANCH|ORIGIN=$ORIGIN|TAGNAME=$TAGNAME]"
else
 mkdir /tmp/$BUILD_TAG
 cd /tmp/$BUILD_TAG
 
 git clone -b master-release-test-mirror-dd $ORIGIN .
 git merge -m "Release of $TAGNAME" $TAGNAME 
 git push origin master-release-test-mirror-dd
 echo "[POST RELEASE] master-release-test-mirror branch update successful"

 git checkout dev-release-test-mirror-dd
 git merge --no-ff origin/$RELEASE_BRANCH
 git push origin dev-release-test-mirror-dd
 echo "[POST RELEASE] dev-release-test-mirror branch update successful"
fi
