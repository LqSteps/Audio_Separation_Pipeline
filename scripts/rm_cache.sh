#!/usr/bin/env bash
#Descrição: Remove arquivos utilizados pela pipeline que já foram processados e enviados ao servidor 1.

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

	while read -r line; do #Lê últimas 80 linhas do log, uma por vez.

		grep -q "Canais_Separados" <<< "$line" #Checa se a dublagem é multicanal (5.1, 6 canais).

		if [[ $? == 0 ]]; then #Multicanal: o nome do file + dublagem é a pasta logo depois de "Canais_Separados/".

			file_name="$(grep -o "Canais_Separados/[^/]*" <<< "$line" | head -1 | cut -d "/" -f 2)"

		else #Mono/estéreo: o nome do file + dublagem é o último pedaço da linha (Saída: .../Stems/mdx_extra/<dublagem>).

			file_name="$(basename "$line")"

		fi

		if [[ -z "$file_name" ]]; then #Sem nome, o find abaixo pegaria tudo. Pula a linha.

			continue

		fi

		grep -q "Status OK" <<< "$line" #Checa se o arquivo passou integralmente com êxito pela pipeline.

		
		if [[ $? == 0 ]]; then #Processa apenas arquivos de acordo com o passo acima.

			#printf "${Purple}[DEBUG]i${ColorReset} - Sucesso\n"

			mapfile -d "" dirs < <( #Busca no diretório de saída correspondências com "nome do filme + dublagem" e coloca os resultados no array "dirs".

				find \
				"$OUTPUT_DIR" \
				-iname "$file_name*" \
				-print0
				
			) #Vim marca este parenteses como erro, acredito ser um falso positivo.

			pgrep demucs > /dev/null #Checa se existe algum processo de separação corrente.

			if [[ "$?" != 0 ]]; then #Apenas apaga arquivos se nada está sendo separado.
			
				for i in "${dirs[@]}"; do 

					printf "\n${Purple}[DEBUG]${ResetColor} - Cache: %s\n" "$i"

					rm -rf "$i" #Apaga tudo contido em cada item do array "dirs".

					log_ok "$i" "DELETADO" "deleted_files.log" #Registra no log, aparece no Hub como "Remoção".
					
					#if [[ -d "$i" ]]; then #Condicional para debug, apenas lista exatamente todos arquivos que seriam excluídos."

					#	ls "$i" 
					#	ls "$i/Stems/$DIRREF/FC"

					#fi

				done

			else

				printf "${BoldIntenseYellow}[AVISO]${ResetColor} Demucs em execução, cache permanece no sistema...\n"
				exit 1

			fi

		fi

	done < <(tail -80 "$LOG_DIR/demucs_split.log")

	echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"

}

main
