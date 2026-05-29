#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$LIB_DIR")"
SCRIPT_DIR="$BASE_DIR/scripts"
LOG_DIR="$BASE_DIR/logs"
MEDIA_DIR="$BASE_DIR/Media"
INPUT_DIR="$MEDIA_DIR/Filmes_Entrada"
OUTPUT_DIR="$MEDIA_DIR/Filmes_Saida"
SERVICE_DIR="$BASE_DIR/services"

help=$(echo -e "\$BASE_DIR = Diretório Raiz. \ 
	\n\$SCRIPT_DIR = Diretório de Scripts. \ 
	\n\$LIB_DIR = Diretório de Bibliotecas. \ 
	\n\$LOG_DIR = Diretório de Logs. \ 
        \n\$MEDIA_DIR = Diretório com subdiretórios de I/O de Mídia. \ 
	\n\$INPUT_DIR = Diretório de Entrada de Vídeos. \ 
	\n\$OUTPUT_DIR = Diretório de Saída de Vídeos.")
