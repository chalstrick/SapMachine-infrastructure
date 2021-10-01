#!/bin/bash
set -ex

# expecting:
# GITHUB_API_ACCESS_TOKEN
# GIT_TAG_NAME
# RELEASE

check_and_make () {
  BUNDLE=$1

  CASK_URL=https://github.com/SAP/homebrew-SapMachine/raw/master/Casks/sapmachine${MAJOR}${EA_DESIG}-${BUNDLE}.rb
  CASK_VER=`curl -L -H "Authorization: token ${GITHUB_API_ACCESS_TOKEN}" ${CASK_URL} | grep '^ *version *' | sed 's/ *version *//g' | sed "s/'//g"`

  if [[ ${CASK_VER} > ${TARGET_CASK_VER} ]]; then
    # There is already a higher version.
    return
  fi

  X64_SHA_URL=https://github.com/SAP/SapMachine/releases/download/${ARTEFACT_DIR}/sapmachine-${BUNDLE}-${ARTEFACT_DESIG}_${OS_NAME}-x64_bin.sha256.dmg.txt
  X64_SHA=`curl -L -H "Authorization: token ${GITHUB_API_ACCESS_TOKEN}" ${X64_SHA_URL} | cut -d ' ' -f 1`

  if [[ ${#X64_SHA} != 64 ]]; then
    # This ain't right!! Anyway, nothing we can do
    return
  fi

  if [[ ${ONLY_X64} == true ]]; then
    python3 SapMachine-Infrastructure/lib/make_cask.py -t ${GIT_TAG_NAME} --sha256sum ${X64_SHA} -i ${BUNDLE} ${PRE_RELEASE_OPT}
    return
  fi

  AARCH_SHA_URL=https://github.com/SAP/SapMachine/releases/download/${ARTEFACT_DIR}/sapmachine-${BUNDLE}-${ARTEFACT_DESIG}_${OS_NAME}-aarch64_bin.sha256.dmg.txt
  AARCH_SHA=`curl -L -H "Authorization: token ${GITHUB_API_ACCESS_TOKEN}" ${AARCH_SHA_URL} | cut -d ' ' -f 1`

  if [[ ${#AARCH_SHA} != 64 && ${ONLY_X64} != true ]]; then
    # This ain't right!! Anyway, nothing we can do
    return
  fi

  python3 SapMachine-Infrastructure/lib/make_cask.py -t ${GIT_TAG_NAME} --sha256sum ${X64_SHA} --aarchsha256sum ${AARCH_SHA} -i ${BUNDLE} ${PRE_RELEASE_OPT}
}

# Main
MAJOR="${GIT_TAG_NAME:11:2}"
VERSION=`echo "${GIT_TAG_NAME:11}" | cut -d '+' -f 1`

if [[ $MAJOR < 17 ]]; then
  ONLY_X64=true
  OS_NAME=osx
else
  ONLY_X64=false
  OS_NAME=macos
fi

ARTEFACT_DIR=`echo "$GIT_TAG_NAME" | sed 's/+/%2B/g'`

if [[ "$RELEASE" == true ]]; then
  ARTEFACT_DESIG="${GIT_TAG_NAME:11}"
  EA_DESIG=''
  TARGET_CASK_VER="${VERSION}"
  PRE_RELEASE_OPT=""
else
  BUILD_NUMBER=`echo "${GIT_TAG_NAME:11}" | cut -d '+' -f 2`
  ARTEFACT_DESIG="${VERSION}-ea.${BUILD_NUMBER}"
  EA_DESIG='-ea'
  TARGET_CASK_VER="${VERSION},${BUILD_NUMBER}"
  PRE_RELEASE_OPT="-p"
fi

check_and_make jre
check_and_make jdk