#!/usr/bin/env sh

set -eu

echo "[entrypoint] 🚀 Starting Wizarr container…"

TARGET=/etc/wizarr/wizard_steps
DEFAULT=/opt/default_wizard_steps

mkdir -p "$TARGET"

if [ -d "$DEFAULT" ]; then
	for src in "$DEFAULT"/*; do
		[ -d "$src" ] || continue # skip non-dirs
		name="$(basename "$src")"
		dst="$TARGET/$name"

		# The dst folder is considered "empty" if it has no regular files
		if [ ! -d "$dst" ] || [ -z "$(find "$dst" -type f -print -quit 2> /dev/null)" ]; then
			echo "[entrypoint] ✨ Seeding default wizard steps for $name…"
			mkdir -p "$dst"
			cp -a "$src/." "$dst/"
		else
			echo "[entrypoint] ↩️  Custom wizard steps for $name detected – keeping user files"
		fi
	done
fi

echo "[entrypoint] 🔧 Applying alembic migrations…"
FLASK_SKIP_SCHEDULER=true uv run --frozen --no-dev flask db upgrade

uv run --frozen --no-dev \
	gunicorn \
	--config gunicorn.conf.py \
	--bind 0.0.0.0:5690 \
	--umask 007 \
	run:app
