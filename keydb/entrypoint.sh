#!/bin/sh

#shellcheck disable=SC2154

apex_ip="10.10.10.10"

if [ "$NOMAD_HOST_IP_keydb" != "$apex_ip" ]; then
	while ! nc -z "$apex_ip" "$NOMAD_HOST_PORT_keydb"; do
		echo "Waiting for KeyDB on apex..."
		sleep 2
	done

	echo "KeyDB on apex reachable; giving it a grace period for loading state..."
	sleep 15
fi

echo "Starting KeyDB server"
exec keydb-server /local/keydb.conf
