#!/bin/bash

# shellcheck disable=SC2154

push() {
	local title="$1"
	local message="$2"
	curl \
		-H "Title: $title" \
		-H "Priority: 2" \
		-d "$message" \
		"$PUSH_SERVER"
}

trap 'push "$(basename $0)" "Error in execution"' err

if [ -n "$radarr_eventtype" ]; then
	service=Radarr
	media_type=Movie
	eventtype="$radarr_eventtype"
	isupgrade="$radarr_isupgrade"

	title="$radarr_movie_title"
	release_title="$radarr_release_title"
	release_size="$radarr_release_size"
elif [ -n "$sonarr_eventtype" ]; then
	service=Sonarr
	media_type=Episode
	eventtype="$sonarr_eventtype"
	isupgrade="$sonarr_isupgrade"

	if [ "$sonarr_eventtype" = "Grab" ]; then
		title="$sonarr_series_title S${sonarr_release_seasonnumber}E${sonarr_release_episodenumbers}"
	else
		title="$sonarr_series_title S${sonarr_episodefile_seasonnumber}E${sonarr_episodefile_episodenumbers}"
	fi

	release_title="$sonarr_release_title"
	release_size="$sonarr_release_size"

elif [ -n "$lidarr_eventtype" ]; then
	service=Lidarr
	media_type=Album
	eventtype="$lidarr_eventtype"

	if [ "$eventtype" = "Grab" ]; then
		title="$lidarr_release_title"
	else
		title="$lidarr_artist_name – $lidarr_album_title"
	fi

	release_title="$lidarr_release_title"
	release_size="$lidarr_release_size"
fi

if [ "$isupgrade" = "True" ]; then
	title="$title (upgraded version)"
fi

release_size=$((release_size / 1024 / 1024))

# For e.g. manual imports
if [[ -z "$release_title" || "$release_title" == "triggered" ]]; then
	release_title=$title
fi

if [ "$eventtype" = "Grab" ]; then
	eventtype="Grabbed"
	msg="$release_title ($release_size MB)"
else
	eventtype="Downloaded"
	msg="$release_title"
fi

push "$service – $media_type $eventtype" "$msg"
