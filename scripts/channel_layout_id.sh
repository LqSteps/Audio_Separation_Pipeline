#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Evita fazer o parsing literal de "*.mp4" caso não haja arquivos mp4 no diretório.
shopt -s nullglob

# Consultar documentação da seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/color_output.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"

# Função responsável por contar múmero de arquivos identificados por canal.
count_files () {
        echo "Arquivos com 8 Canais: $channel_8"
        echo "Arquivos com 6 Canais: $channel_6"
        echo "Arquivos com 3 Canais: $channel_3"
        echo "Arquivos com 2 Canais: $channel_2"
        echo "Arquivos com 1 Canal: $channel_1"
	echo -e "Arquivos Com Layout Não Específicado: $unknow_channels\n"
}

# Função responsável por realocar arquivos de áudio para diretórios com nome do layout + subdiretório com mesmo nome do de entrada que contém as dublagens.
main (){

    channel_8=0
	channel_6=0
	channel_3=0
	channel_2=0
	channel_1=0
	unknow_channels=0

	
	mapfile -d "" files < <(
		find "$INPUT_DIR" \
		-type f \
		-iname "*mp4" \
		-print0
	)

	#Considera que arquivos estão em apenas uma camada abaixo do seu diretório, sem estrutura de árvore, por exemplo ./Dublagens_FilmeX, com os arquivos de vídeo dentro dela sem mais subdiretórios.
	for i in "${files[@]}"; do
		
		clean_input=$(basename "$(dirname "$i")")
		
		# Identificação do layout de canais de cada arquivo e formatação do nome para exibir apenas "stereo, 6 channels etc".
		channel_id=$(ffprobe -show_entries \
		stream=channel_layout "$i" -hide_banner 2>&1 \
		| grep -iE "Audio:" | cut -d "," -f 3)

		format=${channel_id# }
		format_2=$(echo "$format" | tr " " "_")

		# Lógica que impede arquivos sem áudio de serem processados e criarem pastas vazias ou serem movidos no mesmo lugar.
		if [ -z "$format_2" ]; then
    			echo -e "${IntenseYellow}$i não contém stream(s) de áudio!${ResetColor}\n"
    			remove_from_queue "$i"
    			continue
		fi

		# Relatório ao usuário que explicita o tipo de layout de cada arquivo.
		echo -e "${Blue}$i${ResetColor} = ${Green}$format_2${ResetColor}"

		# Cria e move os arquivos para diretórios dos layouts e subdiretório com mesmo nome da pasta do filme que contém as dublagens.
		mkdir -p "$OUTPUT_DIR/$format_2/${clean_input#*/}" 2>/dev/null
		echo "Realocado para pasta $OUTPUT_DIR/$format_2/${clean_input#*/}"
		mv "$i" "$OUTPUT_DIR/$format_2/${clean_input#*/}"

		# Logging de realocação de arquivos.
		log_ok "$i" "$OUTPUT_DIR/$format_2/${clean_input#*/}" "channel_id.log"
		
		# Bloco que incrementa contagem de arquivos para a função "count_files" conforme são realocados.
		echo

		case "$format_2" in
			mono) (( channel_1 ++ ));;
			stereo)	(( channel_2 ++ ));;
			3_channels) (( channel_3 ++ ));;
			6_channels) (( channel_6 ++ ));;
			5.1) (( channel_6 ++ ));;
			"5.1(side)") (( channel_6 ++ ));;
			8_channels) (( channel_8 ++ ));;
			*) (( unknown_channels ++ ));;
		esac
	
	done
}

# Execução da função do loop
main

# Execução da função de contagem de arquivos exibida no stdout.
count_files

# Desabilita a opção da shell, se por algum motivo este script não for executado via subshell.
shopt -u nullglob


