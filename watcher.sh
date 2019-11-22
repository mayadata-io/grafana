#!/bin/bash

REPO=$1;
BRANCH=$2;
USERNAME=$3;
PASSWORD=$4;

# Check the status of the build
# Grep will return 0 (which will be stored in STATUS) while the build is running
curl --silent http://$USERNAME:$PASSWORD@jenkins.mayaonline.io/job/$REPO/job/$BRANCH/lastBuild/api/json | grep result\":null > /dev/null;
STATUS=$?;

# Check for the completion of build after every 60 secs
while [ $STATUS == 0 ]
do
    echo "BUILDING IMAGE";
    sleep 60;
    curl --silent http://$USERNAME:$PASSWORD@jenkins.mayaonline.io/job/$REPO/job/$BRANCH/lastBuild/api/json | grep result\":null > /dev/null;
    STATUS=$?;
done
echo "IMAGE BUILD FINISHED"

# Get the result of the build
VAL=$(curl --silent http://$USERNAME:$PASSWORD@jenkins.mayaonline.io/job/$REPO/job/$BRANCH/lastBuild/api/json | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^result/ {print $2}');
VAL1="${VAL%\"}"
RESULT="${VAL1#\"}"
echo "BUILD RESULT : $RESULT";

# If the build is successful trigger the pipelines else don't
if [ $RESULT == "SUCCESS" ]; then
    exit 0;
else
    exit 1;
fi