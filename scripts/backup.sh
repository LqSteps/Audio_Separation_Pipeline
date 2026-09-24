#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"

mapfile -d "" files < <(
        find "$INPUT_DIR" -type f \
        \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.ts" \) \
        ! -iname "*_480p.mp4" \
        -print0
)

backup_path="$ROOT_DIR/tmp/backup"
mkdir -p "$backup_path"

for i in "${files[@]}"; do

	cut_path="$(echo "$i" | cut -d '/' -f 5-)"
	dir_name="$(dirname "$cut_path")"

	mkdir -p "$ROOT_DIR/tmp/backup/$dir_name"
	rsync -av --progress "$i" "$backup_path/$cut_path"

done
