#!/usr/bin/env bash

set -e

# Terraform Cloud Policy Sets Migration Utility Installation
#   Apache 2 License - Copyright (c) 2019  Robert Peteuil  @RobertPeteuil
#
#     Automatically Download, Extract and Install
#        Latest or Specific Version of Cloud Policy Sets Migration Utility
#
#   from: https://github.com/robertpeteuil/tfc-psm-install

# Uncomment line below to always use 'sudo' to install to /usr/local/bin/
# sudoInstall=true

scriptname=$(basename "$0")
scriptbuildnum="1.5.1"
scriptbuilddate="2019-07-10"

# CHECK DEPENDANCIES AND SET NET RETRIEVAL TOOL
if ! unzip -h 2&> /dev/null; then
  echo "aborting - unzip not installed and required"
  exit 1
fi

if ! curl -h 2&> /dev/null; then
  echo "aborting - curl not installed and required"
  exit 1
fi

displayVer() {
  echo -e "${scriptname}  ver ${scriptbuildnum} - ${scriptbuilddate}"
}

usage() {
  [[ "$1" ]] && echo -e "Download and Install Terraform Cloud Policy Sets Migration Utility - Latest Version unless '-i' specified\n"
  echo -e "usage: ${scriptname} [-i VERSION] [-a] [-c] [-h] [-v]"
  echo -e "     -i VERSION\t: specify version to install in format '0.11.8' (OPTIONAL)"
  echo -e "     -a\t\t: automatically use sudo to install to /usr/local/bin"
  echo -e "     -c\t\t: leave binary in working directory (for CI/DevOps use)"
  echo -e "     -h\t\t: help"
  echo -e "     -v\t\t: display ${scriptname} version"
}

getLatest() {
  LATEST_ARR=($(curl -s https://api.github.com/repos/hashicorp/tfc-policy-sets-migration/releases 2> /dev/null | awk '/tag_name/ {print $2}' | cut -d '"' -f 2 | cut -d 'v' -f 2))

  # make sure latest version isn't beta, rc or alpha
  for ver in "${LATEST_ARR[@]}"; do
    if [[ ! $ver =~ beta ]] && [[ ! $ver =~ rc ]] && [[ ! $ver =~ alpha ]]; then
      LATEST="$ver"
      break
    fi
  done
  echo -n "$LATEST"
}

while getopts ":i:achv" arg; do
  case "${arg}" in
    a)  sudoInstall=true;;
    c)  cwdInstall=true;;
    i)  VERSION=${OPTARG};;
    h)  usage x; exit;;
    v)  displayVer; exit;;
    \?) echo -e "Error - Invalid option: $OPTARG"; usage; exit;;
    :)  echo "Error - $OPTARG requires an argument"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))

# POPULATE VARIABLES NEEDED TO CREATE DOWNLOAD URL AND FILENAME
if [[ -z "$VERSION" ]]; then
  VERSION=$(getLatest)
fi
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "linux" ]]; then
  PROC=$(lscpu 2> /dev/null | awk '/Architecture/ {if($2 == "x86_64") {print "amd64"; exit} else {print "386"; exit}}')
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/flags/ {if($0 ~ /lm/) {print "amd64"; exit} else {print "386"; exit}}')
  fi
else
  PROC="amd64"
fi
[[ $PROC =~ arm ]] && PROC="arm"  # terraform downloads use "arm" not full arm type


# OLD DL URL
# FILENAME="terraform_${VERSION}_${OS}_${PROC}.zip"
# LINK="https://releases.hashicorp.com/terraform/${VERSION}/${FILENAME}"
# SHALINK="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_SHA256SUMS"

# new DL URL
# https://github.com/hashicorp/tfc-policy-sets-migration/releases/download/v0.0.1/tfc-policy-sets-migration-darwin-amd64.zip

# CREATE FILENAME AND URL FROM GATHERED PARAMETERS
FILENAME="tfc-policy-sets-migration-${OS}-${PROC}.zip"
LINK="https://github.com/hashicorp/tfc-policy-sets-migration/releases/download/v${VERSION}/${FILENAME}"


# TEST CALCULATED LINKS
LINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$LINK")

# VERIFY LINK VALIDITY
if [[ "$LINKVALID" != 302 ]]; then
  echo -e "Cannot Install - Download URL Invalid"
  echo -e "\nParameters:"
  echo -e "\tVER:\t$VERSION"
  echo -e "\tOS:\t$OS"
  echo -e "\tPROC:\t$PROC"
  echo -e "\tURL:\t$LINK"
  exit 1
fi

# DETERMINE DESTINATION
if [[ "$cwdInstall" ]]; then
  BINDIR=$(pwd)
elif [[ -w "/usr/local/bin" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX=""
  STREAMLINED=true
elif [[ "$sudoInstall" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX="sudo "
  STREAMLINED=true
else
  echo -e "Terraform Cloud Policy Sets Migration Utility Installer\n"
  echo "Specify install directory (a,b or c):"
  echo -en "\t(a) '~/bin'    (b) '/usr/local/bin' as root    (c) abort : "
  read -r -n 1 SELECTION
  echo
  if [ "${SELECTION}" == "a" ] || [ "${SELECTION}" == "A" ]; then
    BINDIR="${HOME}/bin"
    CMDPREFIX=""
  elif [ "${SELECTION}" == "b" ] || [ "${SELECTION}" == "B" ]; then
    BINDIR="/usr/local/bin"
    CMDPREFIX="sudo "
  else
    exit 0
  fi
fi

# CREATE TMPDIR FOR EXTRACTION
if [[ ! "$cwdInstall" ]]; then
  TMPDIR=${TMPDIR:-/tmp}
  UTILTMPDIR="tfc-psm-${VERSION}"

  cd "$TMPDIR" || exit 1
  mkdir -p "$UTILTMPDIR"
  cd "$UTILTMPDIR" || exit 1
fi

# DOWNLOAD ZIP
curl -L -s -o "$FILENAME" "$LINK"


# EXTRACT ZIP
unzip -qq "$FILENAME" || exit 1

# COPY TO DESTINATION
if [[ ! "$cwdInstall" ]]; then
  mkdir -p "${BINDIR}" || exit 1
  ${CMDPREFIX} cp -f tfc-policy-sets-migration "$BINDIR" || exit 1
  # CLEANUP AND EXIT
  cd "${TMPDIR}" || exit 1
  rm -rf "${UTILTMPDIR}"
  [[ ! "$STREAMLINED" ]] && echo
  echo "tfc-policy-sets-migration Utility v${VERSION} installed to ${BINDIR}"
else
  echo "tfc-policy-sets-migration Utility v${VERSION} downloaded"
fi

exit 0
