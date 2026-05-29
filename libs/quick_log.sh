#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/pathing.sh"

log_ok (){
	echo -e "$(date) Status OK - Entrada: $1 - Saída: $2" >> "$LOG_DIR/$3"
}

log_erro (){
        echo -e "$(date) Status ERRO - Entrada: $1 - Saída: $2" >> "$LOG_DIR/$3"
}

