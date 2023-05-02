#!/bin/sh
set -e
echo "$CREDENTIALS_PLIST" > ~/.apple/Credentials.plist.b64
base64 -d -i ~/.apple/Credentials.plist.b64 > BoatTracker/Credentials.plist
echo "$NETRC" > ~/.apple/netrc.b64
base64 -d -i ~/.apple/netrc.b64 > ~/.netrc
chmod 600 ~/.netrc
ls -al ~/.apple/
