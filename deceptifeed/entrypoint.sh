#!/bin/bash

echo "Waiting for IP feed to come online..."

until curl -Is --output /dev/null --fail "$IP_FEED"; do
	sleep 5
done

echo "IP feed online: starting \`deceptimeed\` loop"
deceptimeed -i 10 "$IP_FEED"
