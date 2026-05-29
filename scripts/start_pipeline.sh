#!/usr/bin/env bash

# Descrição: Executa pipeline completo respeitando a ordem dos scripts do projeto, evita-se paralelismo para scripts não receberem inputs inacabados de passos anteriores.

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

source "../libs/pathing.sh"

"$SCRIPT_DIR/std_reencode.sh"

"$SCRIPT_DIR/channel_layout_id.sh"

"$SCRIPT_DIR/extract_mono_stereo.sh"

"$SCRIPT_DIR/split_multichannel.sh"

"$SCRIPT_DIR/demucs_split.sh"

"$SCRIPT_DIR/transfer_files.sh"

sleep 120
