#!/bin/sh

name=$(echo "$SLSKD_SCRIPT_DATA" | sed 's/.*"localDirectoryName":"\/app\/downloads\/\([^"]*\)".*/\1/')

wget -q -O/dev/null \
	--post-data "name=$name&path=/downloads" \
	--header="X-API-KEY: $BETANIN_API_KEY" \
	--header="User-Agent: auto-import.sh" \
	http://{{ env "NOMAD_IP_betanin" }}:{{ env "NOMAD_HOST_PORT_betanin" }}/api/torrents
