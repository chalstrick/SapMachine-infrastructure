#!/bin/bash
set -ex

UNAME=`uname`
export PATH=$PATH:/usr/bin

if [[ -z $WORKSPACE ]]; then
  WORKSPACE=$PWD
fi

if [[ ! -z $GIT_TAG_NAME ]]; then
  VERSION=${GIT_TAG_NAME:1:3}
else
  VERSION=snapshot
fi


cd "${WORKSPACE}/jmc"

git config user.name SAPMACHINE_GIT_USER
git config user.email SAPMACHINE_GIT_EMAIL

GIT_REVISION=$(git rev-parse HEAD)
echo "Git Revision=${GIT_REVISION}"

if [[ -z $NO_CHECKOUT ]]; then
  if [ "$GITHUB_PR_NUMBER" ]; then
    git fetch origin "pull/$GITHUB_PR_NUMBER/head"
    git merge FETCH_HEAD
  fi

  if [[ ! -z $GIT_TAG_NAME ]]; then
    git checkout $GIT_TAG_NAME
  fi
fi

export PATH="${WORKSPACE}/apache-maven-3.8.4/bin:$PATH"
export JAVA_HOME="${WORKSPACE}/sapmachine-jdk-11.0.14.1"
export PATH="${WORKSPACE}/sapmachine-jdk-11.0.14.1/bin:$PATH"

mvn -f releng/third-party/pom.xml p2:site
mvn -f releng/third-party/pom.xml jetty:run &
sleep 5

mvn -f core/pom.xml clean install
mvn package
mvn install

#mvn verify -P uitests
#mvn verify

#echo "check agent"
#cd agent
#mvn verify
#cd ../core
#mvn verify

echo "jmc/target/products/org.openjdk.jmc-win32.win32.x86_64.zip" > artifact.txt