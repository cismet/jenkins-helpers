#!/bin/bash

SCRIPTS_DIR=$(dirname "$0")

GIT_PASSWORD=*OVERWRITTEN_BY_DOT_SECRETS*
source "$SCRIPTS_DIR/.secrets"

cd $WORKSPACE
touch mergedIssues

HEAD_HASH=`git rev-parse HEAD`

git show-ref --heads | grep $HEAD_HASH | grep dev > /dev/null 2>&1

if [ $? -ne 0 ] ; then
	echo "Not on dev branch, assuming this job is not related to a merge into dev"
	exit 0
fi

## only merges with exactly two parents allowed, feature/bug branch into dev branch
if [ $HEAD_HASH == `git rev-list --min-parents=2 --max-parents=2 HEAD -n 1` ] ; then
	PARENT=`git rev-list --parents HEAD | grep $HEAD_HASH | cut -d' ' -f 2`
	BRANCH=`git ls-remote --heads | grep $PARENT`
	NAMEINDEX=$((`echo "${#PARENT}"` + 12))

	if [ -z "$BRANCH" ] ; then
		PARENT=`git rev-list --parents HEAD | grep $HEAD_HASH | cut -d' ' -f 3`
		BRANCH=`git ls-remote --heads | grep $PARENT`
		NAMEINDEX=$((`echo "${#PARENT}"` + 12))
	
		if [ -z "$BRANCH" ] ; then
			echo "WARNING: could not find merging branch name: has the feature branch been pushed?"
			exit 0
		fi
	fi

	BRANCH=${BRANCH:$NAMEINDEX}

	if [ ${BRANCH:0:7} = "release" ] ; then
		echo "Found release branch, skipping: $BRANCH";
		exit 0;
	fi

	echo "Feature branch: $BRANCH ($PARENT)"

	## add build job link
	MESSAGE="Integrated branch '$BRANCH ($PARENT)' into 'dev ($HEAD_HASH)' -- [Build $BUILD_NUMBER]($BUILD_URL)"

	echo $MESSAGE

	## sed does not support lookahead/behind so we use two steps
	ISSUE_ID=`echo $BRANCH | sed -n "s/.*[/]//p" | sed -n "s/[^0-9].*//p"`
	
	if [ -z "$ISSUE_ID" ] ; then
		# try without slash ...
		ISSUE_ID=`echo $BRANCH | sed -n "s/[^0-9].*//p"`
		if [ -z "$ISSUE_ID" ] ; then
			echo "WARNING: Illegally named issue branch: $BRANCH"
			exit 0
		fi
	fi

	if grep -Fxq "$ISSUE_ID $PARENT $HEAD_HASH" mergedIssues ; then
		echo "Issue has already been integrated from this head, ignoring build: [issue_id=$ISSUE_ID|branch_head=$PARENT|dev_head=$HEAD_HASH]"
		exit 0
	fi

	## we assume that the origin is the one of github
	if [[ ! `git config --get remote.origin.url` =~ "github.com" ]] ; then 
		echo "WARNING: Non-github origin not supported!"
		exit 0
	fi
 
	REPO=`git config --get remote.origin.url | sed -n "s/.*[/]//p" | sed -n "s/.git//p"`
	OWNER=`git config --get remote.origin.url | sed -n "s/\/$REPO.git//p" | sed -n "s/.*[:/]//p"`
	
	URL="https://api.github.com/repos/$OWNER/$REPO/issues/$ISSUE_ID/comments"
	
	echo "Updading issue: $URL"
	
	curl -u "ci-cismet-de:$GIT_PASSWORD" --data "{\"body\": \"$MESSAGE\"}" $URL

	echo "$ISSUE_ID $PARENT $HEAD_HASH" >> mergedIssues
else
	echo "The most recent commit $HEAD_HASH has not been a merge commit, ignoring job"
	exit 0
fi


