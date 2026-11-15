#!/usr/bin/env bash
#Descrição: Remove arquivos utilizados pela pipeline que já foram processados e enviados ao servidor 1.
#O start_pipeline.sh só chama este script quando o transfer_files.sh terminou sem erro.

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"
source "$ROOT_DIR/libs/color_output.sh"

# Consultar documentação na seção "config"
source "$CONFIG_DIR/demucs_config"

echo -e "\n${Bold}[SISTEMA] EXECUÇÃO: LIMPEZA DE CACHE${ResetColor}\n"

main (){

	pgrep demucs > /dev/null #Checa se existe algum processo de separação corrente.

	if [[ "$?" == 0 ]]; then #Apenas apaga arquivos se nada está sendo separado.

		printf "${BoldIntenseYellow}[AVISO]${ResetColor} Demucs em execução, cache permanece no sistema...\n"
		exit 1

	fi

	# Último status de cada arquivo nas últimas 80 linhas do log. Uma dublagem que deu OK, foi reenviada
	# e agora falhou não é apagada: o arquivo dela está em Falhas_Demucs para inspeção.
	declare -A status
	local linha_log='Status (OK|ERRO) - Entrada: (.*) - Saída: '

	while read -r line; do #Lê últimas 80 linhas do log, uma por vez.

		[[ "$line" =~ $linha_log ]] && status["${BASH_REMATCH[2]}"]="${BASH_REMATCH[1]}"

	done < <(tail -80 "$LOG_DIR/demucs_split.log")

	for entrada in "${!status[@]}"; do

		[[ "${status[$entrada]}" == "OK" ]] || continue #Processa apenas arquivos que passaram com êxito pelo Demucs.

		# Caminho a partir de Filmes_Saida: "<layout>/<PASTA DO FILME>/...". O log grava os caminhos do
		# container (/app/...), então a pasta do filme é montada com o $OUTPUT_DIR deste ambiente.
		relativo="${entrada#*/Filmes_Saida/}"
		[[ "$relativo" != "$entrada" ]] || continue
		pasta_filme="$OUTPUT_DIR/$(cut -d "/" -f 1-2 <<< "$relativo")"

		# Nome da dublagem. Nos layouts multicanal o arquivo é sempre FC.wav e o nome é o da pasta em
		# Canais_Separados; em mono/estéreo é o próprio .wav (antes o campo 8 do log saía "app").
		if [[ "$(basename "$entrada")" == "FC.wav" ]]; then
			dublagem="$(basename "$(dirname "$entrada")")"
		else
			dublagem="$(basename "${entrada%.*}")"
		fi

		[[ -n "$dublagem" && -d "$pasta_filme" ]] || continue

		# Escapa [ ] * ? para o nome ser comparado literalmente pelo find.
		nome="$(sed 's/[][*?\\]/\\&/g' <<< "$dublagem")"

		mapfile -d "" dirs < <( #Só o que tem exatamente o nome da dublagem, dentro da pasta do filme: vídeo 480p, .wav, pasta em Canais_Separados e pasta dos stems.

			find \
			"$pasta_filme" \
			\( -name "$nome" -o -name "$nome.mp4" -o -name "$nome.wav" \) \
			-prune \
			-print0

		)

		for i in "${dirs[@]}"; do

			printf "${BoldIntenseCyan}[INFO]${ResetColor} Cache apagado: %s\n" "$i"

			rm -rf "$i" #Apaga tudo contido em cada item do array "dirs".

			log_ok "$i" "DELETADO" "deleted_files.log" #Aparece no Hub como "Remoção".

		done

	done

	echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"

}

main
