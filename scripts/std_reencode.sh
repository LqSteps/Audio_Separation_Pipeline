#!/usr/bin/env bash


readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"
source "$ROOT_DIR/libs/color_output.sh"
# Consultar documentação na seção "config".
source "$ROOT_DIR/config/ffmpeg_config"

echo -e "\n${Bold}[SISTEMA] EXECUÇÃO: DOWNSCALE E REENCODE DOS VÍDEOS${ResetColor}\n"

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

                relative="${i#"$INPUT_DIR"/}"
                output="$ROOT_DIR/tmp/Filmes_Entrada/$(dirname "$relative")/$(basename "${i%.*}")_480p.mp4"
		input="$ROOT_DIR/tmp/Filmes_Entrada/$relative"
		# A lista é montada no início e a pasta de um filme leva dezenas de minutos no reencode, então
		# o arquivo pode sair do Drive antes da vez dele (Jumanji turco e ucraniano em 14/11). Sem esta
		# checagem o rclone falhava, o ffmpeg rodava num arquivo que não existe e a dublagem ia para o
		# log como "corrompido".
		if [ ! -e "$i" ]; then
			echo -e "${BoldIntenseCyan}[INFO] $i saiu da pasta de entrada antes do reencode, ignorado.${ResetColor}"
			continue
		fi

                mkdir -p "$(dirname "$input")"
		#echo "[DEBUG] file: $i"
		if ! rclone --config /dev/null moveto "$i" "$input"; then
			# Continua no Drive e entra no próximo ciclo; a cópia pela metade não pode ficar no tmp.
			[ -e "$i" ] && rm -f "$input"
			echo -e "${BoldIntenseYellow}[AVISO] $i não pôde ser copiado do Drive, fica para o próximo ciclo.${ResetColor}"
			continue
		fi
		#exit 0

                if ffmpeg -loglevel -8 -i "$input" -c:v "$FFMPEG_CODEC" \
                        -s 720x480 \
                        -c:a copy "$output" \
                        -hide_banner; then
                        log_ok "$input" "$output" "std_reencode.log"
                        echo "$output" >> "$queue"
			echo -e "${BoldIntenseGreen}[SUCESSO] $input downscaled para 480p, salvo em $output.${ResetColor}"
                        rm "$input"
                else
                        log_erro "$input" "$input.corrupted" "std_reencode.log"
                        remove_from_queue "$i"
                        rm -f "$output"
			echo -e "${BoldIntenseRed}[ERRO] $input corrompido, não foi processado.${ResetColor}"
                        mv "$input" "$input.corrupted"
                fi
        done

}

main

echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"
