#!/bin/bash

# name=$(echo "$SLSKD_SCRIPT_DATA" | sed 's/.*"localDirectoryName":"\/app\/downloads\/\([^"]*\)".*/\1/')
name=$(jq -r '.localDirectoryName | sub("^/app/downloads/";"")' <<< "$SLSKD_SCRIPT_DATA")

wget -q -O /dev/null \
	--post-data "name=$name&path=/downloads" \
	--header="X-API-KEY: $BETANIN_API_KEY" \
	--header="User-Agent: auto-import.sh" \
	"http://$BETANIN_ADDR/api/torrents"
