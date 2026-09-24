#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação na seção de libs.
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/color_output.sh"

# Consultar documentação na seção de configs.
source "$ROOT_DIR/config/network_config"

echo -e "\n${Bold}[SISTEMA] EXECUÇÃO: TRANSFERÊNCIA DE ARQUIVOS${ResetColor}"

# Transferência de arquivos que não constam no destino (servidor 1)
echo -e "${BoldIntenseCyan} [INFO] Enviando arquivos à equipe de edição...${ResetColor}"
rsync -rv --checksum "$OUTPUT_DIR" -e "ssh -p 31754" "$SSH_AGENT:/mnt/16tb/Audio_Separation_Pipeline/Media"
rsync -rv --checksum "$LOG_DIR" -e "ssh -p 31754" "$SSH_AGENT:/mnt/16tb/Audio_Separation_Pipeline"
echo -e "${BoldIntenseGreen} [SUCESSO] Arquivos enviados.${ResetColor}"

echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"
