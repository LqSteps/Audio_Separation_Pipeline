#!/usr/bin/env bash


readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/color_output.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"

# Divide vídeos longos em partes logo depois do reencode, antes da identificação de layout e da extração de áudio.
# O Demucs guarda o áudio inteiro na RAM: Avatar (3h17) estourou a memória, Alita (2h02) passou.
# Cada parte vira um vídeo comum ("Filme X ingles PARTE 1_480p.mp4"), igual ao que foi feito à mão no Avatar,
# então todos os layouts (mono, stereo, 5.1...) e os scripts seguintes funcionam sem mudança.

# Vídeos com duração acima deste limite (em segundos) são divididos. 9000s = 2h30m.
# Para testar com arquivos menores: LIMITE_DURACAO=1000 ./video_split.sh
LIMITE_DURACAO="${LIMITE_DURACAO:-9000}"

# Duração máxima de cada parte, em segundos. 3600s = 1h.
# As partes saem do mesmo tamanho: um filme de 3h17 vira 4 partes de ~49min, e não 3 de 1h e uma de 17min.
TAMANHO_PARTE="${TAMANHO_PARTE:-3600}"

# As partes são geradas aqui e só depois movidas para tmp/Filmes_Entrada, assim o
# channel_layout_id.sh nunca pega uma parte pela metade se o processo for interrompido.
tmp_dir="$BASE_DIR/tmp/video_split.parcial"

limite_txt="$((LIMITE_DURACAO / 3600))h$(printf "%02d" $((LIMITE_DURACAO % 3600 / 60)))m"

printf "\n${Bold}[SISTEMA] Início da execução de divisão de vídeos maiores que %s.${ResetColor}\n" "$limite_txt"

mapfile -d "" files < <(

	find "$BASE_DIR/tmp/Filmes_Entrada" -type f -name "*_480p.mp4" -print0

)


debug_info (){

	printf "[DEBUG] arquivo: %s\n" "$i"
	printf "\n[DEBUG] clean_basename: %s\n" "$clean_basename"
	printf "\n[DEBUG] dir_name: %s\n" "$dir_name"
	printf "\n[DEBUG] duration: %s\n\n" "$duration"

}

for i in "${files[@]}"; do

	base_name="$(basename "$i")"

	# "Filme X ingles_480p.mp4" -> "Filme X ingles"
	clean_basename="${base_name%_480p.mp4}"

	dir_name="$(dirname "$i")"

	duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$i")"


	if [[ "$1" == "--debug" ]]; then

		debug_info

	fi


	# ffprobe pode devolver vazio ou "N/A"; nesse caso o vídeo segue inteiro, como antes deste script existir.
	if [[ ! "$duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then

		printf "${IntenseRed}[ERRO]${ResetColor} %s: ffprobe não conseguiu ler a duração, segue sem dividir.\n" "$i"

		log_erro "$i" "$i" "video_split.log"

		continue

	fi

	segundos="${duration%.*}"


	if (( segundos <= LIMITE_DURACAO )); then

		printf "[INFO] %s: Possui menos de %s de duração, segue inteiro.\n" "$i" "$limite_txt"

		continue

	fi


	partes=$(( (segundos + TAMANHO_PARTE - 1) / TAMANHO_PARTE ))

	# O +1 evita que a fração de segundo que sobra no fim vire uma parte extra de poucos segundos.
	tempo_parte=$(( segundos / partes + 1 ))

	printf "[INFO] %s: Possui mais de %s de duração, dividindo em %d partes...\n" "$i" "$limite_txt" "$partes"

	rm -rf -- "$tmp_dir"

	mkdir -p -- "$tmp_dir"


	# -c copy só corta, sem reencodar: leva segundos. Cada corte cai no primeiro keyframe depois de
	# tempo_parte, e nenhum pacote de áudio se perde ou se repete entre as partes.
	if ! ffmpeg -nostdin -v error -i "$i" \
		-map 0 \
		-c copy \
		-f segment \
		-segment_time "$tempo_parte" \
		-reset_timestamps 1 \
		-segment_start_number 1 \
		"$tmp_dir/parte%d.mp4"; then

		rm -rf -- "$tmp_dir"

		log_erro "$i" "$tmp_dir" "video_split.log"

		printf "\n${IntenseRed}[ERRO]${ResetColor} %s falhou na divisão, segue inteiro. Consulte a integridade do arquivo.\n" "$i"

		continue

	fi


	geradas=0

	while [[ -f "$tmp_dir/parte$((geradas + 1)).mp4" ]]; do

		(( geradas++ ))

	done


	# Sem keyframes suficientes o ffmpeg gera um arquivo só; aí não adianta trocar o original.
	if (( geradas < 2 )); then

		rm -rf -- "$tmp_dir"

		log_erro "$i" "$tmp_dir" "video_split.log"

		printf "\n${IntenseRed}[ERRO]${ResetColor} %s gerou só %d parte(s), segue inteiro.\n" "$i" "$geradas"

		continue

	fi


	partes_finais=()

	for (( n = 1; n <= geradas; n++ )); do

		parte="$dir_name/${clean_basename} PARTE ${n}_480p.mp4"

		mv -- "$tmp_dir/parte$n.mp4" "$parte"

		partes_finais+=("$parte")

		log_ok "$i" "$parte" "video_split.log"

	done


	# O original só sai depois que todas as partes estão no lugar. Se o processo cair antes disso,
	# o próximo ciclo refaz a divisão e sobrescreve as partes.
	rm -f -- "$i"

	rm -rf -- "$tmp_dir"

	replace_in_queue "$i" "${partes_finais[@]}"

	printf "${IntenseGreen}[SUCESSO]${ResetColor} %s foi dividido em %d partes, disponíveis em %s\n" "$i" "$geradas" "$dir_name"

done

printf "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n\n"
