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

# Troca um vídeo da fila pelas suas partes, na mesma posição. Usado pelo video_split.sh.
# Argumento 1: vídeo original. Demais argumentos: caminhos das partes.
# Os caminhos vão por variável de ambiente porque o "awk -v" interpretaria "\" nos nomes.
replace_in_queue() {
    local queue="$BASE_DIR/tmp/file_queue.txt"

    [ -f "$queue" ] || return 0

    ORIGINAL="/$(basename "$1")" PARTES="$(printf '%s\n' "${@:2}")" awk '
        BEGIN { original = ENVIRON["ORIGINAL"]; partes = ENVIRON["PARTES"] }
        substr($0, length($0) - length(original) + 1) == original { print partes; next }
        { print }
    ' "$queue" > "$BASE_DIR/tmp/file_queue.tmp"

    mv \
        "$BASE_DIR/tmp/file_queue.tmp" \
        "$queue"
}
