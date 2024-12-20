#!/bin/sh

if [ "$MODE" = "json-rpc" ]; then
	/usr/bin/jsonrpc2-helper
fi

service supervisor start
supervisorctl start all

signal-cli-rest-api -signal-cli-config="$SIGNAL_CLI_CONFIG_DIR"
