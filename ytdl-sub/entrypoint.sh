#!/bin/bash

set -Eeuo pipefail

log=/logs/cron.log

: > "$log"
exec &> >(tee -a "$log")

push() {
	local title="$1"
	local message="$2"
	curl \
		-H "Authorization: Bearer $PUSH_TOKEN" \
		-H "Title: $title" \
		-H "Priority: 2" \
		-d "$message" \
		"$PUSH_SERVER"
}

on_error() {
	push "$(basename "$0") encountered an error"
}

trap 'on_error' err

ytdl-sub \
	--log-level info \
	--config /local/config.yaml \
	sub /local/subscriptions.yaml
