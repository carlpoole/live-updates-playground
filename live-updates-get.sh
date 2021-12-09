#!/usr/bin/env bash

# Default channel for development builds
channel="Development"

# Get args
while getopts i:c:o: flag
do
    case "${flag}" in
        i) id=${OPTARG};;
        c) channel=${OPTARG};;
        o) output=${OPTARG};;
        *) echo "usage: $0 [-i] [-c] [-o]" >&2
            exit 1 ;;
    esac
done

# Exit if app id not provided
if [[ -z "$id" ]];
then
    echo "Please specify an app id with the -i flag!"
    exit 1
fi

# Exit if output not provided
if [[ -z "$output" ]];
then
    echo "Please specify an output with the -o flag!"
    exit 1
fi

echo "App id: $id";
echo "Channel: $channel";

checkURL="https://api.ionicjs.com/apps/$id/channels/check-device"
checkBody="{ \"app_id\":\"$id\", \"channel_name\": \"$channel\", \"device\": { \"platform\":\"android\", \"binary_version\":\"30\" } }"

checkResult=$(curl -s -X POST -H "Content-Type: application/json" -d "$checkBody" "$checkURL")

if grep -q '"available": true' <<< "$checkResult"; then
    snapshot="$(grep -o '"snapshot": "[^"]*' <<< "$checkResult" | grep -o '[^"]*$')"
    downloadURL="$(grep -o '"url": "[^"]*' <<< "$checkResult" | grep -o '[^"]*$')" 

    # Exit if unable to determine snapshot or download URL
    if [[ -z "$snapshot" ]] || [[ -z "$downloadURL" ]];
    then
        echo "No download URL or snapshot ID available to download."
        exit 1
    fi

    echo "Latest Live Update published for app $id: snapshot $snapshot"

    # Check if zip for snapshot already exists before downloading
    snapshotFile=./$snapshot.zip
    if [[ -f "$snapshotFile" ]]; then
        echo "$snapshot.zip already downloaded, skipping..."
        exit 0    
    else
        echo "Downloading $snapshot.zip..."    
        downloadURL="$(grep -o '"url": "[^"]*' <<< "$checkResult" | grep -o '[^"]*$')"
        curl -s -L "$downloadURL" --output "$snapshot".zip
    fi

    # Check if the output directory exists already
    if [[ -d "$output" ]]; then
        rm -rf "$output"
    fi

    mkdir -p "$output"
    unzip "$snapshot".zip -d "$output"
else
    echo "No update available"
fi
