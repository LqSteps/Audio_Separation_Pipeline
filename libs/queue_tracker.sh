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

# Devolve à fila as dublagens que já foram extraídas e ainda esperam o Demucs. Usado pelo std_reencode.sh,
# que zera a fila no início de cada ciclo: se o container reinicia no meio do Demucs, a fila ficava só
# com os vídeos novos, apesar de o Demucs ainda ir processar as outras.
# Precisa do $DIRREF (config/demucs_config) para saber se a dublagem já tem stems.
requeue_pending() {
    local pendentes i pasta nome

    # Os mesmos arquivos que o demucs_split.sh processa: .wav de mono/estéreo e FC.wav dos multicanal.
    mapfile -d "" pendentes < <(
        find "$OUTPUT_DIR" -type f \
        \( -path "*/mono/*.wav" -o -path "*/stereo/*.wav" -o -name "FC.wav" \) \
        -not -path "*/Stems/*" \
        -not -path "*/Falhas_Demucs/*" \
        -not -path "*.parcial/*" \
        -print0
    )

    for i in "${pendentes[@]}"; do

        pasta="$(dirname "$i")"
        nome="$(basename "${i%.*}")"

        # Já tem stems: o Demucs terminou essa dublagem.
        if [ -d "$pasta/Stems/$DIRREF/$nome" ]; then
            continue
        fi

        # Multicanal: .../<FILME>/Canais_Separados/<dublagem>/FC.wav, e o vídeo é .../<FILME>/<dublagem>.mp4
        # Mono/estéreo: .../<FILME>/<dublagem>.wav, com o vídeo na mesma pasta.
        if [ "$nome" == "FC" ]; then
            echo "$(dirname "$(dirname "$pasta")")/$(basename "$pasta").mp4" >> "$BASE_DIR/tmp/file_queue.txt"
        else
            echo "$pasta/$nome.mp4" >> "$BASE_DIR/tmp/file_queue.txt"
        fi

    done
}
