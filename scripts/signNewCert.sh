#!/bin/bash

cd $WORKSPACE

# only as long as we use a final name we can use this script
# should not be necessary anymore as soon as automatic gen is introduced
FINAL_NAME=`cat pom.xml | grep -o -P '(?<=<finalName>).+(?=</finalName>)'`

if [ -z "$FINAL_NAME" ] ; then
	echo "INFO: no explicit final name set, assuming not part of legacy distribution"
	exit 0
fi

DIST_DIR=`cat $HOME/.m2/settings.xml | grep -o -P '(?<=<de.cismet.cidsDistDir>).+(?=</de.cismet.cidsDistDir>)'`
DIST_DIR_NEW="$DIST_DIR"_newSign

if [ ! -d $DIST_DIR_NEW ] ; then
	mkdir $DIST_DIR_NEW
fi
if [ ! -d $DIST_DIR_NEW/lib ] ; then
	mkdir $DIST_DIR_NEW/lib
fi
if [ ! -d $DIST_DIR_NEW/lib/int ] ; then
	mkdir $DIST_DIR_NEW/lib/int
fi

TARGET=$DIST_DIR_NEW/lib/int/$FINAL_NAME.jar

cp $DIST_DIR/lib/int/$FINAL_NAME.jar $TARGET

echo $TARGET

zip -d $TARGET META-INF/\*.SF META-INF/\*.RSA META-INF/\*.DSA

jarsigner -keystore $HOME/cismet_keystore -storepass <insert-pw-here> $TARGET cismet 

if [ $? -ne 0 ] ; then
	echo "WARNING: signing not successful, removing jar $TARGET"
	rm $TARGET
fi

exit 0;
