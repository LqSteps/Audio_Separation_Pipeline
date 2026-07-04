#!/usr/bin/env bash
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"
source "$ROOT_DIR/libs/color_output.sh"
# Consultar documentação na seção "config".
source "$ROOT_DIR/config/ffmpeg_config"

# Array que contém arquivos de vídeo, com exceção dos que já foram reencodados e comprimidos para 480p.
mapfile -d "" files < <(
        find "$INPUT_DIR" -type f \
        \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.ts" \) \
        ! -iname "*_480p.mp4" \
        -print0
)

queue="$BASE_DIR/tmp/file_queue.txt"
touch "$queue"
: > "$queue"
echo "Fila:" >> "$queue"

# Função principal responsável por padronizar arquivos de entrada em h264 e 480p.
main (){
        for i in "${files[@]}"; do
                relative="${i#$INPUT_DIR/}"
                output="$ROOT_DIR/tmp/Filmes_Entrada/$(dirname "$relative")/$(basename "${i%.*}")_480p.mp4"
		input="$ROOT_DIR/tmp/Filmes_Entrada/$relative"
                mkdir -p "$(dirname "$input")"
		mv "$i" "$input"

                if ffmpeg -i "$input" -c:v "$FFMPEG_CODEC" \
                        -s 720x480 \
                        -c:a copy "$output" \
                        -hide_banner; then
                        log_ok "$input" "$output" "std_reencode.log"
                        echo "$output" >> "$queue"
                        rm "$input"
                else
                        echo "Corrompido, pulando..."
                        log_erro "$input" "$input.corrupted" "std_reencode.log"
                        remove_from_queue "$i"
                        rm -f "$output"
                        mv "$input" "$input.corrupted"
                fi
        done
}
main
