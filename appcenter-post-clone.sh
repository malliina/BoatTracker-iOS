#!/usr/bin/env bash

echo "Running appcenter-post-clone.sh ..."
if [ ! -n "$MapboxCocoapodsToken" ]
then
    echo "You need define the MapboxCocoapodsToken environment variable in App Center"
    exit
fi

# Injects .netrc file required during pod install because Mapbox
if [ "$APPCENTER_BRANCH" == "master" ];
then
    echo "machine api.mapbox.com" >> ~/.netrc
    echo "login mapbox" >> ~/.netrc
    echo "password $MapboxCocoapodsToken" >> ~/.netrc
    echo "Wrote ~/.netrc"
fi
