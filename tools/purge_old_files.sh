#!/usr/bin/env bash
# Autor: Pedro
# Data de Criação: 08/02/2026
# Data de Modificação: 06/06/2026
# Descrição: Remove vídeos e áudios com mais de X dias localizados no path: /Audio_Separation_Pipeline/Media.

if [ "$EUID" -ne 0 ]; then
    echo "Execute com sudo."
    exit 1
fi

shopt -s nullglob 

MaxAge="$1"

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/color_output.sh"

Path="$ROOT_DIR/Media"

#Cria log em /GitHub/Repos/Demucs_Split/Scripts/stdout

mapfile -d "" files < <(

	find "$Path" \
	\( -name '.*' -prune \) -o \
	\( -mtime +"$MaxAge" \( -name '*.mp4' \
	-o -name '*.mp3' -o -name "*.wav" \
	-o -name '*.aac' \
	-o -name '*.ts' \) \) \
	-print0
)

for i in "${files[@]}"; do

	log_ok "$i" "${BoldRed}DELETADO${ResetColor}" "deleted_files.log" 


	# Deleta arquivos com mais de X dias (editar variável MaxAge)
	find "$Path" 1 -mtime +$MaxAge ! -path '*/.*' \( -name '*.mp4' -o -name '*.mp3' -o -name '*.aac' -o -name '*.wav' -o -name '*.ts' \) -delete


done

size="$(du -ch "${files[@]}" | tail -1 | cut -d "	" -f 1)"

current_space="$(df -h | grep -i "/dev/md2" | cut -d " " -f 32)"
total_space="$(df -h | grep -i "/dev/md2" | cut -d " " -f 30)"

echo -e "\nArquivos deletados: ${BoldRed}${#files[@]}${ResetColor}"

echo -e "\nEspaço liberado: ${BoldIntenseGreen}$size${ResetColor}"

echo -e "\nEspaço Disponível: $current_space de $total_space"

echo -e "\nUltimos 10 arquivos deletados:\n \n$(cat "$LOG_DIR/deleted_files.log" | tail -n 10)"

echo -e "\nConsulte o log completo em logs/deleted_files.log"



shopt -u nullglob
