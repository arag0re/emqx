#!/usr/bin/env bash

## This script helps to download relup base version packages

if [[ -n "$DEBUG" ]]; then
    set -x
fi
set -euo pipefail

PROFILE="${1}"
if [ "$PROFILE" = "" ]; then
    PROFILE="emqx"
fi

case $PROFILE in
    "emqx")
        DIR='broker'
        EDITION='community'
        ;;
    "emqx-ee")
        DIR='enterprise'
        EDITION='enterprise'
        ;;
    "emqx-edge")
        DIR='edge'
        EDITION='edge'
        ;;
esac

SYSTEM="${SYSTEM:-$(./scripts/get-distro.sh)}"

ARCH="${ARCH:-$(uname -m)}"
case "$ARCH" in
    x86_64)
        ARCH='amd64'
        ;;
    aarch64)
        ARCH='arm64'
        ;;
    arm*)
        ARCH=arm
        ;;
esac


case "$SYSTEM" in
    windows*)
        echo "WARNING: skipped downloading relup base for windows because we do not support relup for windows yet."
        exit 0
        ;;
    macos*)
        SHASUM="shasum -a 256"
        ;;
    *)
        SHASUM="sha256sum"
        ;;
esac

# ensure dir
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

mkdir -p _upgrade_base
pushd _upgrade_base

for tag in $(../scripts/relup-base-vsns.sh $EDITION | xargs echo -n); do
    filename="$PROFILE-${tag#[e|v]}-otp$OTP_VSN-$SYSTEM-$ARCH.zip"
    url="https://www.emqx.com/downloads/$DIR/${tag#[e|v]}/$filename"
    echo "downloading base package from ${url} ..."
    if [ ! -f "$filename" ] && curl -I -m 10 -o /dev/null -s -w "%{http_code}" "${url}" | grep -q -oE "^[23]+" ; then
        curl -L -o "${filename}" "${url}"
        if [ "$SYSTEM" != "centos6" ]; then
            curl -L -o "${filename}.sha256" "${url}.sha256"
            SUMSTR=$(cat "${filename}.sha256")
            echo "got sha265sum: ${SUMSTR}"
            ## https://askubuntu.com/questions/1202208/checking-sha256-checksum
            echo "${SUMSTR}  ${filename}" | $SHASUM -c || exit 1
        fi
    fi
done

popd