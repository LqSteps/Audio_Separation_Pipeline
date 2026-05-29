#!/usr/bin/env bash

# Consultar documentação na seção de libs.
source "../libs/pathing.sh"

# Consultar documentação na seção de configs.
source "../config/network_config"

# Transferência de arquivos que não constam no destino (servidor 1)
rsync -rv "../Media/Filmes_Saida" "$SSH_AGENT:/mnt/16tb/Audio_Separation_Pipeline/Media"

