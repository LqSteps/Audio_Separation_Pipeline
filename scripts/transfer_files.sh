#!/usr/bin/env bash

# Consultar documentação na seção de libs.
source "../libs/pathing.sh"

# Transferência de arquivos que não constam no destino (servidor 1)
rsync -rv "../Media/Filmes_Saida" "root@157.180.2.67:/mnt/16tb/Audio_Separation_Pipeline/Media"

