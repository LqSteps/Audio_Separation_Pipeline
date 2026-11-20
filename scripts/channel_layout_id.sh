#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Evita fazer o parsing literal de "*.mp4" caso não haja arquivos mp4 no diretório.
shopt -s nullglob

# Consultar documentação da seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/color_output.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"

# Consultar documentação na seção "config". Só para o $DIRREF, a pasta dos stems (Stems/mdx_extra).
source "$ROOT_DIR/config/demucs_config"

echo -e "\n${Bold}[SISTEMA] EXECUÇÃO: IDENTIFICAÇÃO DE LAYOUTS DE ÁUDIO${ResetColor}"

# Função responsável por contar múmero de arquivos identificados por canal.
count_files () {
        echo -e "${IntenseCyan}[INFO] Arquivos com 8 Canais: $channel_8${ResetColor}"
        echo -e "${IntenseCyan}[INFO] Arquivos com 6 Canais: $channel_6${ResetColor}"
        echo -e "${IntenseCyan}[INFO] Arquivos com 3 Canais: $channel_3${ResetColor}"
        echo -e "${IntenseCyan}[INFO] Arquivos com 2 Canais: $channel_2${ResetColor}"
        echo -e "${IntenseCyan}[INFO] Arquivos com 1 Canal: $channel_1${ResetColor}"
	echo -e "${IntenseCyan}[INFO] Arquivos Com Layout Não Específicado: $unknown_channels\n${ResetColor}"
}

# Função responsável por realocar arquivos de áudio para diretórios com nome do layout + subdiretório com mesmo nome do de entrada que contém as dublagens.
main (){

    channel_8=0
	channel_6=0
	channel_3=0
	channel_2=0
	channel_1=0
	unknown_channels=0

	
	# Só os vídeos reencodados (inclusive "PARTE N_480p.mp4"), não a cópia full-res que sobra de um reencode interrompido.
	mapfile -d "" files < <(
		find "$ROOT_DIR/tmp/Filmes_Entrada" \
		-type f \
		-iname "*_480p.mp4" \
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
    			echo -e "${BoldIntenseYellow}[AVISO] $i não contém stream(s) de áudio!${ResetColor}\n"
    			remove_from_queue "$i"
    			continue
		fi

		# Relatório ao usuário que explicita o tipo de layout de cada arquivo.
		echo -e "${Blue}$i${ResetColor} = ${Green}$format_2${ResetColor}"

		# Cria e move os arquivos para diretórios dos layouts e subdiretório com mesmo nome da pasta do filme que contém as dublagens.
		mkdir -p "$OUTPUT_DIR/$format_2/${clean_input#*/}" 2>/dev/null

		# Dublagem enviada de novo com o mesmo nome (ex.: falhou no Demucs e foi subida outra vez no Drive): apaga o que
		# sobrou da tentativa anterior, para ela ser processada do zero. Sem isso a pasta antiga em Canais_Separados fazia
		# o split_multichannel.sh pular o vídeo novo, e o .wav antigo (ou o de Falhas_Demucs) fazia o extract_mono_stereo.sh
		# pular, então a dublagem nunca chegava ao Demucs (007 Skyfall inglês, 11/2026).
		destino="$OUTPUT_DIR/$format_2/${clean_input#*/}"
		nome="$(basename "${i%.*}")" #Ex.: "007 – skyfall ingles_480p".
		if [ -e "$destino/Canais_Separados/$nome" ] || [ -e "$destino/$nome.wav" ] || [ -e "$destino/Falhas_Demucs/$nome.wav" ] || [ -e "$destino/Stems/$DIRREF/$nome" ]; then
			echo -e "${BoldIntenseYellow}[AVISO] $nome já passou pela pipeline antes, o resultado anterior foi apagado para processar de novo.${ResetColor}"
			rm -rf "$destino/Canais_Separados/$nome" "$destino/$nome.wav" "$destino/Falhas_Demucs/$nome.wav" "$destino/Stems/$DIRREF/$nome"
		fi

		echo -e "${BoldIntenseCyan}[INFO] Realocado para pasta $OUTPUT_DIR/$format_2/${clean_input#*/}${ResetColor}"
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

		# 3.0, 7.1 e outros layouts não têm suporte (precisariam de outra arquitetura): o demucs_split.sh só
		# processa os layouts da primeira linha abaixo. O vídeo continua indo para Filmes_Saida/<layout>, mas sai
		# da fila e ganha uma linha de ERRO no log, para aparecer no Hub em vez de ficar parado sem aviso.
		case "$format_2" in
			mono|stereo|5.1|"5.1(side)"|6_channels) ;; #Com suporte, nada a fazer.
			*)
				echo -e "${BoldIntenseYellow}[AVISO] Layout $format_2 sem suporte, $i não vai para o Demucs.${ResetColor}\n"
				log_erro "$i" "$OUTPUT_DIR/$format_2/${clean_input#*/}" "channel_id.log"
				remove_from_queue "$i"
				;;
		esac
	
	done

}

# Execução da função do loop
main

# Execução da função de contagem de arquivos exibida no stdout.
count_files

# Desabilita a opção da shell, se por algum motivo este script não for executado via subshell.
shopt -u nullglob

echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"
