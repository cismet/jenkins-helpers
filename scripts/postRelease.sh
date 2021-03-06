#!/bin/bash

set -e

cd $WORKSPACE
if ! grep -a -q "\[INFO\] Cleaning up after release..." $JENKINS_HOME/jobs/$JOB_NAME/builds/$BUILD_NUMBER/log ; then
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
elif [[ $RELEASE_BRANCH == *-pre || $RELEASE_BRANCH == *-pre-* || $RELEASE_BRANCH == *-prerelease || $RELEASE_BRANCH == *-prerelease-* ]] ; then 
 echo "[POST RELEASE] skipping master- and dev- merge of pre-release branch: $RELEASE_BRANCH"
else
 mkdir /tmp/$BUILD_TAG
 cd /tmp/$BUILD_TAG
 
 git clone -b master $ORIGIN .
 git merge -m "Release of $TAGNAME" $TAGNAME 
 git push origin master
 echo "[POST RELEASE] master branch update successful"

 git checkout dev
 git merge --no-ff origin/$RELEASE_BRANCH
 git push origin dev
 echo "[POST RELEASE] dev branch update successful"
fi
