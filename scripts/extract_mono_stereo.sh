#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Consultar documentação da seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"

# Função responsável pelo processamento da versão em .wav pcm. O argumento 1 faz a função trabalhar apenas com o layout de áudio indicado, 
# este script foi pensado para aceitar mono, stereo e 3.0.
#
processar (){

	# Busca na pasta "Filmes_Saída/layout de audio"
	mapfile -d "" files < <(
		find "$OUTPUT_DIR/$1" \
		-type f \
		-iname "*.mp4" \
		-print0
	)
	
	# Loop que processa arquivos válidos.
	for i in "${files[@]}"; do
		
		# Lógica que evita reprocessamento de arquivos que já existem em .wav.
		if [ -f "${i%.*}.wav" ]; then
			echo "${i%.*}.wav já existe, pulando..."
		continue
		fi
	
		if ffmpeg -vn -v error \
		-i "$i" \
		-hide_banner \
		-c:a pcm_f32le \
		"${i%.*}.wav"; then

			# Processamento funcionou, registrado no log.
			echo "$(basename "$i") Convertido para WAV"
			log_ok "$i" "${i%.*}.wav" "$1_wav.log"
		else
			# Processamento falhou, registrado no log e arquivo recebe a extensão .corrupted, 
			# para evitar reprocessamento e indicar estrutura problemática.
			mv "$i" "${i%.*}.corrupted"
			echo "Corrompido, pulando ..."
			log_erro "$i" "${i%.*}.corrupted" "$1_wav.log"
			remove_from_queue "$i"
		fi

	done
}

# Execução da função com layouts de áudio escolhidos.
processar mono
processar stereo
