#!/bin/sh
set -e
mkdir ~/.apple/
echo "$CREDENTIALS_PLIST" > ~/.apple/Credentials.plist.b64
base64 -d -i ~/.apple/Credentials.plist.b64 > $CI_PRIMARY_REPOSITORY_PATH/BoatTracker/Credentials.plist
echo "$NETRC" > ~/.apple/netrc.b64
base64 -d -i ~/.apple/netrc.b64 > ~/.netrc
chmod 600 ~/.netrc
ls -al ~/.apple/
