#!/usr/bin/env bash

if [ ! -n "$MapboxAccessToken" ]
then
    echo "You need define the MapboxAccessToken environment variable in App Center"
    exit
fi
if [ ! -n "$GoogleClientId" ]
then
    echo "You need define the GoogleClientId environment variable in App Center"
    exit
fi
if [ ! -n "$MapboxCocoapodsToken" ]
then
    echo "You need define the MapboxCocoapodsToken environment variable in App Center"
    exit
fi

# Injects credentials to a plist file
if [ "$APPCENTER_BRANCH" == "master" ];
then
    echo "Copying Credentials-template.plist to Credentials.plist and injecting credentials"
    cp $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials-template.plist $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials.plist
    echo "Updating Mapbox access token to $MapboxAccessToken in Credentials.plist"
    plutil -replace MapboxAccessToken -string $MapboxAccessToken $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials.plist
    echo "Updating Google client ID to $GoogleClientId in Credentials.plist"
    plutil -replace GoogleClientId -string $GoogleClientId $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials.plist
    echo "machine api.mapbox.com" >> ~/.netrc
    echo "login mapbox" >> ~/.netrc
    echo "machine $MapboxCocoapodsToken" >> ~/.netrc
fi
