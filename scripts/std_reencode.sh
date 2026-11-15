#!/usr/bin/env bash


readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"
source "$ROOT_DIR/libs/color_output.sh"
# Consultar documentação na seção "config".
source "$ROOT_DIR/config/ffmpeg_config"
source "$ROOT_DIR/config/demucs_config"

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
requeue_pending # Dublagens de ciclos anteriores que ainda esperam o Demucs (ver libs/queue_tracker.sh).

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
		# copyto, e não moveto: o original só sai do Drive depois do reencode (rm -f "$i" mais abaixo). Com o
		# moveto, um container reiniciado no meio do ffmpeg deixava o original só no tmp, fora da lista do
		# próximo ciclo, que só olha o Drive.
		if ! rclone --config /dev/null copyto "$i" "$input"; then
			# Continua no Drive e entra no próximo ciclo; a cópia pela metade não pode ficar no tmp.
			rm -f "$input"
			echo -e "${BoldIntenseYellow}[AVISO] $i não pôde ser copiado do Drive, fica para o próximo ciclo.${ResetColor}"
			continue
		fi
		#exit 0

		# Grava em "<nome>_480p.mp4.parcial" e só renomeia quando o ffmpeg termina: um vídeo pela metade não
		# segue na pipeline. "-f mp4" porque a extensão ".parcial" não diz o formato; "-y" sobrescreve a sobra.
                if ffmpeg -y -loglevel -8 -i "$input" -c:v "$FFMPEG_CODEC" \
                        -s 720x480 \
                        -c:a copy -f mp4 "$output.parcial" \
                        -hide_banner; then
                        mv "$output.parcial" "$output"
                        log_ok "$input" "$output" "std_reencode.log"
                        echo "$output" >> "$queue"
			echo -e "${BoldIntenseGreen}[SUCESSO] $input downscaled para 480p, salvo em $output.${ResetColor}"
                        rm "$input"
                        rm -f "$i" # Só agora o original sai do Drive.
                else
                        log_erro "$input" "$input.corrupted" "std_reencode.log"
                        remove_from_queue "$i"
                        rm -f "$output.parcial"
			echo -e "${BoldIntenseRed}[ERRO] $input corrompido, não foi processado.${ResetColor}"
                        mv "$input" "$input.corrupted"
                        rm -f "$i" # Sai do Drive como antes; a cópia .corrupted fica no tmp para inspeção.
                fi
        done

}

main

echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"
