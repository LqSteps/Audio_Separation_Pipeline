#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Consultar documentação da seção "libs".
source "$ROOT_DIR/libs/pathing.sh"
source "$ROOT_DIR/libs/quick_log.sh"
source "$ROOT_DIR/libs/queue_tracker.sh"

channel3_dir="$OUTPUT_DIR/3_channels"
channel6_dir="$OUTPUT_DIR/6_channels"
channel_5_1_side="$OUTPUT_DIR/5.1(side)"
channel_5_1="$OUTPUT_DIR/5.1"

# Arrays que contém todos arquivos ".mp4" na pasta de entrada,
# esses vídeos são o output reencodado do script "std_reencode.sh".

#Fix temporário de vários arrays até eu ter tempo de transformar tudo isso em uma função só.
mapfile -d "" files3 < <(
        find "$channel3_dir" -type f \
        -iname "*.mp4" \
        -print0 2>/dev/null
)

mapfile -d "" files6 < <(
        find "$channel6_dir" -type f \
        -iname "*.mp4" \
        -print0 2>/dev/null
)

mapfile -d "" files5_1_side < <(
        find "$channel_5_1_side" -type f \
        -iname "*.mp4" \
        -print0 2>/dev/null
)

mapfile -d "" files5_1 < <(
        find "$channel_5_1" -type f \
        -iname "*.mp4" \
        -print0 2>/dev/null
)


# Função responsável por mapear os canais do arquivo, independentemente do layout,
# assim permite que formatos não especificados resultem em erro.
processar_channel3 (){

        for i in "${files3[@]}"; do
                local dir="$(dirname "$i")"
                local base="$(basename "${i%.*}")"
                local split_path="$dir/Canais_Separados/$base"

                if [ -d "$split_path" ]; then

                        echo -e "$(basename "$i") existe, pulando..."

                else

                        # Após mapeamento, os canais são padronizados para pcm float em .wav e enviados para
                        # "Nome da pasta do arquivo de input/Canais_Separados/nome do arquivo de entrada sem extensão/FL.wav etc"
                        mkdir -p "$split_path"
                        if ffmpeg -hide_banner -vn -i "$i" \
                        -filter_complex "[0:a]pan=1c|c0=c0[FL];[0:a]pan=1c|c0=c1[FR];[0:a]pan=1c|c0=c2[FC]" \
                        -map "[FL]"  -c:a pcm_f32le "$split_path/FL.wav" \
                        -map "[FR]"  -c:a pcm_f32le "$split_path/FR.wav" \
                        -map "[FC]"  -c:a pcm_f32le "$split_path/FC.wav"; then

                                # Processamento OK - Registro no log com status OK.
                                log_ok "$i" "$split_path" "extrair_3canais.log"
                        else
                                # Processamento ERRO - Registro no log com status ERRO.
                                log_erro "$i" "$split_path" "extrair_3canais.log"
                                remove_from_queue "$i"
                                # Adiciona extensão .corrupted ao arquivo, para inspeção posterior e evitar reprocessamento.
                                mv "$i" "$i.corrupted"
                        fi

                fi

        done
}

# Mesma lógica da função processar_channel3, porém com o payload do ffmpeg voltado para o mapeamento de layouts de audio 5.1.
processar_5_1_layouts (){

        local -n arr="$1"

        for i in "${arr[@]}"; do
                local dir="$(dirname "$i")"
                local base="$(basename "${i%.*}")"
                local split_path="$dir/Canais_Separados/$base"

                if [ -d "$split_path" ]; then

                        echo -e "$(basename "$i") existe, pulando..."

                else
                        mkdir -p "$split_path"
                        if ffmpeg -hide_banner -vn -i "$i" \
                        -filter_complex "[0:a]pan=1c|c0=c0[FL];[0:a]pan=1c|c0=c1[FR];[0:a]pan=1c|c0=c2[FC];[0:a]pan=1c|c0=c3[LFE];[0:a]pan=1c|c0=c4[SL];[0:a]pan=1c|c0=c5[SR]" \
                        -map "[FL]"  -c:a pcm_f32le "$split_path/FL.wav" \
                        -map "[FR]"  -c:a pcm_f32le "$split_path/FR.wav" \
                        -map "[FC]"  -c:a pcm_f32le "$split_path/FC.wav" \
                        -map "[LFE]" -c:a pcm_f32le "$split_path/LFE.wav" \
                        -map "[SL]"  -c:a pcm_f32le "$split_path/SL.wav" \
                        -map "[SR]"  -c:a pcm_f32le "$split_path/SR.wav"; then

                                log_ok "$i" "$split_path" "extrair_6_canais.log"
                        else
                                log_erro "$i" "$split_path" "extrair_6_canais.log"
                                mv "$i" "$i.corrupted"
                        fi

                fi

        done
}

processar_channel3

# Concentrar tudo em uma call na próxima atualização
processar_5_1_layouts files6
processar_5_1_layouts files5_1_side
processar_5_1_layouts files5_1
