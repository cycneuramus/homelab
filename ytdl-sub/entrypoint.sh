#!/bin/bash

set -Eeuo pipefail

log=/logs/cron.log

: > "$log"
exec &> >(tee -a "$log")

push() {
	local title="ytdl-sub"
	local message="$1"
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

# https://github.com/jmbannon/ytdl-sub/blob/5b76e628077ef5b92265f51788f3ec43bb14a869/docker/root/custom-cont-init.d/defaults#L29C1-L41C3
if [ "$UPDATE_YT_DLP_ON_START" == "stable" ]; then
	echo "UPDATE_YT_DLP_ON_START is set to stable, attempting to update to a new stable version of yt-dlp if it exists."
	python3 -m pip install -U "yt-dlp[default]"
elif [ "$UPDATE_YT_DLP_ON_START" == "nightly" ]; then
	echo "UPDATE_YT_DLP_ON_START is set to nightly, attempting to update to the latest nightly version of yt-dlp."
	python3 -m pip install -U --pre "yt-dlp[default]"
elif [ "$UPDATE_YT_DLP_ON_START" == "master" ]; then
	echo "UPDATE_YT_DLP_ON_START is set to master, pulling yt-dlp's latest commit for install."
	python3 -m pip install -U pip hatchling wheel
	python3 -m pip install --force-reinstall "yt-dlp[default] @ https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"
else
	echo "UPDATE_YT_DLP_ON_START is not set, using packaged version."
fi

ytdl-sub \
	--log-level info \
	--config /local/config.yaml \
	sub /local/subscriptions.yaml

if ! grep -qi "No files changed" "$log"; then
	push "New media may have been found"
fi
