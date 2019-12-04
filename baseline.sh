#!/bin/sh
set -x

TAG=$1

REPO=$2

BRANCH=$3

# Clone repo director-charts-internal
git clone git@github.com:mayadata-io/director-charts-internal.git

cd director-charts-internal/

# Checkout to dop-e2e branch
git checkout dop-e2e

# Create a new directory for preparation of helm chart with Repository name and commit tag
mkdir $REPO-$TAG

# Get the previous directory created by baseline.sh
PREV_REPO=$(cat baseline | awk -F',' 'NR==1{print $3}' | awk -F'=' '{print $2}')
PREV_TAG=$(cat baseline | awk -F',' 'NR==1{print $NF}' | awk -F'=' '{print $2}')

# Copy the contents of the previous directory into the new directory
cp -rf $PREV_REPO-$PREV_TAG/. $REPO-$TAG/

# Replace the previous image tag of grafana with the new image tag
sed 's/image: mayadata\/maya-grafana:.*/image: mayadata\/maya-grafana:'${TAG}'/' -i ./$REPO-$TAG/templates/dep-maya-grafana.yaml

# Update version in Chart.yaml
sed 's/version:.*/version: '${TAG}'/' -i ./$REPO-$TAG/Chart.yaml

# Update appVersion in Chart.yaml
sed 's/appVersion:.*/appVersion: '${TAG}'/' -i ./$REPO-$TAG/Chart.yaml

git status 

# Update the new commit tag in the baseline file 
ansible-playbook commit-writer.yml --extra-vars "branch=$BRANCH repo=$REPO commit=$TAG"

git add .

git status

git commit -m "updated $REPO commit:$TAG"

git push  git@github.com:mayadata-io/director-charts-internal.git --all
