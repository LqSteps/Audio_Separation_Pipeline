#!/usr/bin/env bash

remove_from_queue() {
    local file
    file="$(basename "${1%.*}").mp4"

    grep -Fv "/$file" "$BASE_DIR/tmp/file_queue.txt" \
        > "$BASE_DIR/tmp/file_queue.tmp"

    mv \
        "$BASE_DIR/tmp/file_queue.tmp" \
        "$BASE_DIR/tmp/file_queue.txt"
}
