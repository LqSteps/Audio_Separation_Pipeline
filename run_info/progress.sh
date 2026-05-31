#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "Execute com sudo."
    exit 1
fi

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/libs/pathing.sh"

while true; do
	clear
	cat "$BASE_DIR/tmp/current_file_demucs.txt"
	cat "$BASE_DIR/tmp/current_progress_demucs.txt"
	sleep 1
	
done
