#!/bin/sh

set -eu

: "${UV_CACHE_DIR:=/app/cache}"
export HOME="${HOME:-$UV_CACHE_DIR}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$UV_CACHE_DIR}"

if [ ! -f /app/requirements.txt ]; then
	echo "requirements.txt not found in /app" >&2
	exit 1
fi

mkdir -p /app/venv "$UV_CACHE_DIR"

if [ ! -x /app/venv/bin/python ]; then
	echo "[entrypoint] Creating venv at /app/venv"
	uv venv /app/venv --seed
fi

echo "[entrypoint] Installing/updating dependencies"
uv pip install -r /app/requirements.txt --upgrade -p /app/venv/bin/python

if ! /app/venv/bin/gunicorn --version > /dev/null 2>&1; then
	echo "gunicorn not found in venv" >&2
	exit 1
fi

echo "[entrypoint] Starting gunicorn on 0.0.0.0:8000"
/app/venv/bin/gunicorn app:APP \
	--bind 0.0.0.0:8000 \
	--workers "${WEB_CONCURRENCY:-2}" \
	--threads "${THREADS:-2}" \
	--timeout "${TIMEOUT:-60}" \
	--graceful-timeout 30 \
	--access-logfile - \
	--error-logfile -
