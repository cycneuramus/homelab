#!/bin/bash

set -e

HOSTNAME=$(hostname)
NAS_HOST=horreum

CPU_THRESHOLD=50
DISK_SPACE_THRESHOLD_GB=15
NAS_SPACE_THRESHOLD_GB=5000
TEMP_THRESHOLD=70
HIGH_LOAD_TRIGGER_LIMIT=5

TEMP_PATH=/sys/class/hwmon/hwmon2/temp1_input
NEWLINE=$'\n'

CHECK_INTERVAL=10m

log() {
	local this_log="[$1]: $2"

	if [[ "$this_log" != "$latest_log" ]]; then
		echo "$(date +"[%Y-%m-%d %H:%M:%S]"): $this_log"
		latest_log=$this_log
	fi
}

push() {
	local this_push="$HOSTNAME: $1"

	if [[ "$this_push" != "$latest_push" ]]; then
		log "INFO" "Issue encountered; pushing notification..."
		curl \
			-H "Authorization: Bearer $PUSH_TOKEN" \
			-H "Title: $HOSTNAME" \
			-H "Priority: 2" \
			-d "$1" \
			"$PUSH_SERVER"

		latest_push="$this_push"
	fi
}

load() {
	cpu=$(mpstat 2 1 | awk '/Average/ {print int(100 - $NF)}')

	if [[ -f "$TEMP_PATH" ]]; then
		temp=$(sed 's/...$//' $TEMP_PATH)
		sysinfo="CPU: $cpu%${NEWLINE}Temp: $temp°"
	else
		log "WARNING" "Temperature path ($TEMP_PATH) not found"
		temp=0
		sysinfo="CPU: $cpu%"
	fi

	should_notify=0

	if ((cpu > CPU_THRESHOLD || temp > TEMP_THRESHOLD)); then
		if ((trigger_count++ >= HIGH_LOAD_TRIGGER_LIMIT)); then
			should_notify=1
			trigger_count=0
		else
			log "INFO" "High load triggers: $trigger_count"
		fi
	else
		if ((trigger_count > 0)); then
			log "INFO" "Resetting high load triggers"
		fi

		trigger_count=0
	fi

	if ((should_notify == 1)); then
		msg="Server under high continual load"
		proc_stats="$(ps -eo pcpu,args --sort=-pcpu | awk 'NR >= 2 && NR <= 6 { print $1"%",$2 }')"

		push "${msg}${NEWLINE}${NEWLINE}${sysinfo}${NEWLINE}${NEWLINE}${proc_stats}"
	fi
}

disk() {
	free_gb=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')

	if ((free_gb < DISK_SPACE_THRESHOLD_GB)); then
		push "Low disk space: $free_gb GB remaining"
	fi

	if [[ "$HOSTNAME" == "$NAS_HOST" ]]; then
		free_gb=$(df --output=avail -BG /mnt/nas | tail -1 | tr -dc '0-9')

		if ((free_gb < NAS_SPACE_THRESHOLD_GB)); then
			push "Low nas space: $free_gb GB remaining"
		fi
	fi
}

mounts() {
	for mnt in nas jfs; do
		mountpoint -q /mnt/"$mnt" || push "$mnt mount is unhealthy"
	done
}

systemd() {
	services=(
		keepalived
		mnt-jfs
		mnt-nas
		nomad
		podman
		ufw
		unattended-upgrades
	)

	for s in "${services[@]}"; do
		if [[ $(systemctl is-failed "$s".service) == "failed" ]]; then
			push "Systemd service failed: $s.service"
		fi
	done
}

oom() {
	if [[ -f ~/oom ]]; then
		file_stat=$(stat -c '%w' ~/oom)
		file_create_time=$(date -d "$file_stat" '+%H:%M:%S')
		push "A container was OOM killed at $file_create_time"
		rm ~/oom
	fi
}

trap 'push "Sysmonitor job encountered an error on line $LINENO: $BASH_COMMAND"' err
log "INFO" "Starting monitor"

while sleep $CHECK_INTERVAL; do
	load
	disk
	mounts
	systemd
	oom
done
