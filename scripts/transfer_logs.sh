#!/usr/bin/env bash


shopt -s nullglob

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação da seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/color_output.sh"

# Consultar documentação da seção "config"
source "$ROOT_DIR/config/network_config"

main (){

	tmp_log_path="$ROOT_DIR/tmp/logs"
	mkdir -p "$tmp_log_path"

	cp  -r "$LOG_DIR" "$tmp_log_path/.."

	cd "$tmp_log_path"

	for i in *.log; do
		chmod 777 "$i"
		mv "$i" "${i%.*}.txt"
	done

	rsync -rv --checksum "$tmp_log_path" -e "ssh -p 31754" \
		"$SSH_AGENT:/mnt/16tb/Audio_Separation_Pipeline"

	echo -e "${BoldIntenseGreen}Registros atualizados na $1 - \
		$(date)${ResetColor}"
}

main produção

#main dev
