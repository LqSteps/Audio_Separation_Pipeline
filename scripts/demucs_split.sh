#!/usr/bin/env bash

# Path do Demucs na venv

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly VENV_DIR="$ROOT_DIR/.venv"
readonly DEMUCS="$VENV_DIR/bin/demucs"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/color_output.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"

# Consultar documentação na seção "config".
source "$ROOT_DIR/config/demucs_config"

echo -e "\n${Bold}[SISTEMA] EXECUÇÃO: SEPARAÇÃO DE TRILHAS SONORAS${ResetColor}"

# Função que acha arquivos .wav que não foram processados e roda o demucs. 
# O argumento 1 indica qual layout de canais o script  busca, o 2 indica qual faixa será processada, referente a layouts de 6 canais ou mais.
processar: (){

	# Array que contém todos arquivos .wav fora os resultados do demucs, as falhas e as pastas ".parcial"
	# que o split_multichannel.sh ainda está gerando.
	mapfile -d "" files < <(
		find "$OUTPUT_DIR/$1" \
		-type f \
		-iname "*$2.wav" \
		-not -path "*/Stems/*" \
		-not -path "*/Falhas_Demucs/*" \
		-not -path "*.parcial/*" \
		-print0
	)
	
	# Processamento do Demucs.
	for i in "${files[@]}"; do

		# Tira o vídeo da fila. Nos layouts multicanal o arquivo é sempre FC.wav, então o nome
		# do vídeo é o da pasta em Canais_Separados (antes saía "FC.mp4" e nada era removido).
		if [ -n "$2" ]; then
			remove_from_queue "$(dirname "$i").mp4"
		else
			remove_from_queue "${i%.*}.mp4"
		fi

		stems_dir="$(dirname "${i}")/Stems/$MODEL/$(basename "${i%.*}")"

		# A lista é montada no início e a etapa leva dias, então o arquivo pode ter sido apagado
		# no meio do caminho. O Demucs sai com status 0 quando o arquivo não existe, e sem esta
		# checagem ele ia para o log como "Status OK" em 3 segundos sem gerar stem nenhum.
		if [ ! -f "$i" ]; then
			echo -e "${BoldIntenseYellow}[AVISO] $i não existe mais, pulado.${ResetColor}"
			continue
		fi

		# Checa se o resultado já existe, se sim, pula, se não, processa. O vocals.wav é o último stem que o
		# Demucs grava, então uma pasta de stems pela metade (container reiniciado) não conta como pronta.
		if [ -s "$stems_dir/vocals.wav" ]; then

			#echo -e "${BoldIntenseYellow}$i já processado${ResetColor}"
			continue

		else
			# Disco cheio faria o Demucs falhar depois de horas e a dublagem iria para Falhas_Demucs.
			livre=$(df --output=avail -BG "$OUTPUT_DIR" | tail -1 | tr -d " G") #Espaço livre em GB.
			if [ "$livre" -lt 100 ]; then
				echo -e "${BoldIntenseYellow}[AVISO] Só ${livre}G livres, $i fica para o próximo ciclo.${ResetColor}"
				continue
			fi

			mkdir -p "$BASE_DIR/tmp"
			touch "$BASE_DIR/tmp/current_file_demucs.txt"
			touch "$BASE_DIR/tmp/current_progress_demucs.txt"
			current_file_log="$BASE_DIR/tmp/current_file_demucs.txt"
			current_progress="$BASE_DIR/tmp/current_progress_demucs.txt"
			demucs_saida="$BASE_DIR/tmp/demucs_saida.txt" #Tudo o que o Demucs escreve no stderr, para o log de erros.
			echo -e "${BoldIntenseCyan}[INFO] Processando $i...${ResetColor}" >"$current_file_log"

			# Checa se o processamento foi executado corretamente.	
			echo -e "${BoldIntenseCyan}[INFO] Processando $i...${ResetColor}"
			
                        total=$((SHIFTS * 4))
                        if PYTHONWARNINGS="ignore" "$DEMUCS" -n "$MODEL" --overlap 0.1 \
                        --shifts "$SHIFTS" --segment "$SEGMENT" -o \
			"$(dirname "${i}")/Stems" "$i" >/dev/null  2> >(tee "$demucs_saida" | (counter=1; prev=""; while IFS= read -r -d $'\r' line; do [[ "$prev" == *"100%"* && "$line" != *"100%"* ]] && ((counter++)); echo -e "${BoldIntenseGreen}$counter/$total${ResetColor}|$line" > "$current_progress"; prev="$line"; done)) \
			&& [ -s "$stems_dir/vocals.wav" ]; then
				echo -e "${BoldIntenseGreen}[SUCESSO] $i processado com sucesso.${ResetColor}"
				# Resultado OK > Entrada com Status OK no log.
				log_ok "$i" "$stems_dir" "demucs_split.log"

			else
				codigo=$? #Código de saída do Demucs: 137 = morto pelo sistema (falta de memória), 139 = segfault, 1 = erro do Python ou vocals.wav não gerado.
				sleep 1 #Dá tempo do tee terminar de gravar a saída do Demucs.
				# Antes o erro do Demucs não ficava salvo em lugar nenhum. Agora as últimas linhas vão para logs/demucs_erros.log.
				echo "$(date) Código $codigo - $i" >> "$LOG_DIR/demucs_erros.log"
				tail -c 6000 "$demucs_saida" | tr "\r" "\n" | tail -40 >> "$LOG_DIR/demucs_erros.log"
				echo >> "$LOG_DIR/demucs_erros.log"

				echo -e "${BoldIntenseRed}[ERRO] $i falhou (código $codigo, detalhes em logs/demucs_erros.log), realocado para o diretório $(dirname "${i}")/Falhas_Demucs${ResetColor}"
				# Resultado ERRO > Entrada com Status ERRO no log.
				log_erro "$i" "$(dirname "${i}")/Falhas_Demucs/$(basename "${i}")" "demucs_split.log"

				# Arquivos que não foram processados são encaminhados ao diretório
				# "Falhas_Demucs" para posterior inspeção e não serem reprocessados.
				mkdir -p "$(dirname "${i}")/Falhas_Demucs"
				mv "$i" "$(dirname "${i}")/Falhas_Demucs"

			fi	

			exit 0 #Uma dublagem por volta: o start_pipeline.sh envia, limpa e começa a próxima volta.
		fi
	done

}

# Execução da função com argumentos como descrito no comentário acima da função "processar". 
processar: mono
processar: stereo
processar: 5.1 FC
processar: "5.1(side)" FC
processar: 6_channels FC

echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"
