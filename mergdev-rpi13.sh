#!/bin/sh
################################################################################
# Script to setup access to the mergdev apt repository
#
#
#   12 January, 2026 - E M Thornber
#   Created from similar script on rpi5bookworm32
#
################################################################################

# Apt Repository URL on Github
REPOURL="https://emthornber.github.io/RPi13Repo"
# Public Key file name
KEYFILE="gpg-pubkey2.asc"
# Keyring file name
KEYRINGFILE="mergdev-archive-keyring2.gpg"

# -e - exit immediately if a command exits with non-zero status
# -u - treat unset variables as an error when substituting
set -eu

help() {
  echo "Usage: $0 [--release <raspbian-release>]" > /dev/stderr
}

doing=
rc=
release=
help=
for opt in "$@"
do
  case "${doing}" in
  release)
    release="${opt}"
    doing=
    ;;
  "")
    case "${opt}" in
    --release)
      doing=release
      ;;
    --help)
      help=1
      ;;
    esac
    ;;
  esac
done

if [ -n "${doing}" ]
then
  echo "--${doing} option given no argument." > /dev/stderr
  echo > /dev/stderr
  help
  exit 1
fi

if [ -n "${help}" ]
then
  help
  exit
fi

if [ -z "${release}" ]
then
  unset VERSION_CODENAME
  unset ID
  . /etc/os-release

  if [ "${ID}" != "raspbian" ] && [ "${ID}" != "debian" ]
  then
    echo "This is not a Raspbian system. Aborting." > /dev/stderr
    exit 1
  fi

  release="${VERSION_CODENAME}"
fi

case "${release}" in
trixie)
  packages=
  keyring_packages="ca-certificates gpg wget"
  ;;
*)
  echo "Only Raspbian trixie (stable) is supported. Aborting." > /dev/stderr
  exit 1
  ;;
esac

get_keyring=
if [ ! -f /usr/share/keyrings/${KEYRINGFILE} ]
then
  packages="${packages} ${keyring_packages}"
  get_keyring=1
fi

# Start the real work
set -x

apt-get update
# shellcheck disable=SC2086
apt-get install -y ${packages}

test -n "${get_keyring}" && (wget -O - ${REPOURL}/raspbian/${KEYFILE} 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/${KEYRINGFILE} > /dev/null )

echo "deb [signed-by=/usr/share/keyrings/${KEYRINGFILE}] ${REPOURL}/raspbian/ ${release} main" > /etc/apt/sources.list.d/mergdev.list

apt-get update
