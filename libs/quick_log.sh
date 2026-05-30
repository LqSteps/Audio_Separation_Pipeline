#!/usr/bin/env bash
if [ -z "$ROOT_DIR" ]; then
    ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
source "$ROOT_DIR/libs/pathing.sh"
log_ok (){
        echo -e "$(date) Status OK - Entrada: $1 - Saída: $2" >> "$LOG_DIR/$3"
}
log_erro (){
        echo -e "$(date) Status ERRO - Entrada: $1 - Saída: $2" >> "$LOG_DIR/$3"
}
