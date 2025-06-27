#!/bin/bash

HOST=10.10.10.10
PORT=16380

INTERVAL=10

start_cmds=$(redis-cli -h $HOST -p $PORT INFO stats | awk -F: '/total_commands_processed/{print $2}' | tr -d '\r')
start_bytes=$(redis-cli -h $HOST -p $PORT INFO stats | awk -F: '/total_net_output_bytes/{print $2}' | tr -d '\r')

sleep $INTERVAL

end_cmds=$(redis-cli -h $HOST -p $PORT INFO stats | awk -F: '/total_commands_processed/{print $2}' | tr -d '\r')
end_bytes=$(redis-cli -h $HOST -p $PORT INFO stats | awk -F: '/total_net_output_bytes/{print $2}' | tr -d '\r')

cmds_per_sec=$(((end_cmds - start_cmds) / INTERVAL))
bytes_per_sec=$(((end_bytes - start_bytes) / INTERVAL))

echo "Commands per second: $cmds_per_sec"
echo "Network output bytes per second: $bytes_per_sec"
