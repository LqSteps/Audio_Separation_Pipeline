#!/usr/bin/env bash
# Descrição: Executa pipeline completo respeitando a ordem dos scripts do projeto, evita-se paralelismo para scripts não receberem inputs inacabados de passos anteriores.
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/libs/color_output.sh"
source "$ROOT_DIR/libs/pathing.sh"

time=120

echo -e "${Bold}[SISTEMA] Iniciando pipeline de extração de dublagens...${ResetColor}"
while true; do
	"$SCRIPT_DIR/backup.sh"
	"$SCRIPT_DIR/std_reencode.sh"
	"$SCRIPT_DIR/video_split.sh"
	"$SCRIPT_DIR/channel_layout_id.sh"
	"$SCRIPT_DIR/extract_mono_stereo.sh"
	"$SCRIPT_DIR/split_multichannel.sh"
	"$SCRIPT_DIR/demucs_split.sh"
	"$SCRIPT_DIR/transfer_files.sh"
	transferencia=$?
	"$SCRIPT_DIR/transfer_logs.sh"
	rm -rf "$ROOT_DIR/tmp/backup/"
	# Só apaga o cache quando o envio ao servidor 1 deu certo.
	if [[ "$transferencia" == 0 ]]; then
		"$SCRIPT_DIR/rm_cache.sh"
	fi
	sleep 120
	sleep "$time"

echo -e "${Bold}[SISTEMA] Aguardando $time segundos para reinício do ciclo.${ResetColor}"
done
