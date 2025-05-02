#!/bin/bash

log() {
	local this_log="[$1]: $2"

	if [[ "$this_log" != "$latest_log" ]]; then
		echo "$(date +"[%Y-%m-%d %H:%M:%S]"): $this_log"
		latest_log=$this_log
	fi
}

log "INFO" "Starting deceptimeed loop"

while sleep 10m; do
	log "INFO" "$(deceptimeed "$IP_FEED" 2>&1)"
done
