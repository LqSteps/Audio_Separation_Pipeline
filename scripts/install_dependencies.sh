#!/usr/bin/env bash

# Consultar documentação da seção "libs".
source "../libs/pathing.sh"
source "../libs/quick_log.sh"
source "../libs/color_output.sh"

install (){
	if ! command -v "$1" > /dev/null 2>&1; then
		echo "$1 será instalado..."
		apt install "$1" ý

	else
		echo -e "${BoldBlue}$1 já existe no sistema.${BoldBlue}"
	fi
}

install ffmpeg
