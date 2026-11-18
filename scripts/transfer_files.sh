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
# -t guarda a data de modificação no servidor 1, e o rsync compara só tamanho e data. O --checksum lia e calculava
# o hash de todo o Filmes_Saida nos dois servidores a cada ciclo. O primeiro envio com -t ainda lê tudo uma vez,
# para gravar as datas. "*.parcial" é arquivo ou pasta que o ffmpeg ainda não terminou (ver extract_mono_stereo.sh).
# --timeout (rsync) e ConnectTimeout/ServerAlive (ssh) derrubam uma conexão meio aberta, em vez de travar o laço.
status=0
rsync -rtv --timeout=600 --exclude "*.parcial" "$OUTPUT_DIR" -e "ssh -p 31754 -o ConnectTimeout=30 -o ServerAliveInterval=30 -o ServerAliveCountMax=4" "$SSH_AGENT:/mnt/16tb/Audio_Separation_Pipeline/Media" || status=1
rsync -rtv --timeout=600 "$LOG_DIR" -e "ssh -p 31754 -o ConnectTimeout=30 -o ServerAliveInterval=30 -o ServerAliveCountMax=4" "$SSH_AGENT:/mnt/16tb/Audio_Separation_Pipeline" || status=1

# O status de saída diz ao start_pipeline.sh se pode rodar a limpeza: com falha no envio, o
# clean_output.sh apagaria stems que nunca chegaram ao servidor 1.
if [[ "$status" == 0 ]]; then
	echo -e "${BoldIntenseGreen} [SUCESSO] Arquivos enviados.${ResetColor}"
else
	echo -e "${BoldIntenseRed} [ERRO] Falha no envio ao servidor 1, nada será apagado neste ciclo.${ResetColor}"
fi

echo -e "\n${Bold}[SISTEMA] FINALIZADO/FILA VAZIA.${ResetColor}\n"
exit "$status"
