#!/usr/bin/env bash

# Injects credentials to a plist file
if [ "$APPCENTER_BRANCH" == "master" ];
then
	cp $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials-template.plist $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials.plist
    plutil -replace MapboxAccessToken -string "\$(MapboxAccessToken)" $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials.plist
    plutil -replace GoogleClientId -string "\$(GoogleClientId)" $APPCENTER_SOURCE_DIRECTORY/BoatTracker/Credentials.plist
fi

