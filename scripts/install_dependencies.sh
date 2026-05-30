#!/usr/bin/env bash
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação da seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/color_output.sh"

# Executa configuração de váriaveis de ambiente o systemd.
sudo "$ROOT_DIR/config/systemd_config"

install (){
	if ! command -v "$1" > /dev/null 2>&1; then
		echo "$1 será instalado..."
		apt install "$1" -y

	else
		echo -e "${BoldBlue}$1 já existe no sistema.${BoldBlue}"
	fi
}

install ffmpeg

mkdir -p "$LOG_DIR"

if [ ! -f /etc/systemd/system/demucs_pipeline.service ]; then

    ln -s "$SERVICE_DIR/demucs_pipeline.service" /etc/systemd/system/demucs_pipeline.service
    systemctl daemon-reload
    systemctl enable demucs_pipeline.service

    echo "Instalado com sucesso. Inicie com: systemctl start demucs_pipeline.service"

else
    echo "Serviço já instalado"
fi
