#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"

# Consultar documentação na seção "config".
source "$ROOT_DIR/config/ffmpeg_config"

# Array que contém arquivos de vídeo, com exceção dos que já foram reencodados e comprimidos para 480p.
mapfile -d "" files < <(
	find "$INPUT_DIR" -type f \
	\( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.ts" \) \
	! -iname "*_480p.mp4" \
	-print0
)

# Função principal responsável por padronizar arquivos de entrada em h264 e 480p.
main (){
		
	for i in "${files[@]}"; do
		if ffmpeg -i "$i" -c:v "$FFMPEG_CODEC" \
			-s 720x480 \
			-c:a copy "${i%.*}_480p.mp4" \
			-hide_banner; then
			
			# Processamento Ok - Registro no log com status OK.
			log_ok "$i" "${i%.*}_480p.mp4" "std_reencode.log"
			
			rm "$i"
		else 
			echo "Corrompido, pulando..."
			# Processamento ERRO - Registro no log com status ERRO.
			log_erro "$i" "$i.corrupted" "std_reencode.log"

			# Adiciona extensão ".corrupted" 
			# para arquivos corrompidos que não foram processados.
			mv "$i" "$i.corrupted"
		fi

	done

}

main
