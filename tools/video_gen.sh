#!/bin/bash

LAYOUTS=("mono" "stereo")
COUNT=${1:-2}

channels() {
  case "$1" in
    mono)       echo 1 ;;
    stereo)     echo 2 ;;
    5.1)        echo 6 ;;
    5.1\(side\)) echo 6 ;;
    *)          echo 2 ;;
  esac
}

pan_expr() {
  local layout="$1"
  local ch
  ch=$(channels "$layout")

  local expr="${layout}|"

  for ((j=0; j<ch; j++)); do
    expr+="c${j}=c0"
    (( j < ch-1 )) && expr+="|"
  done

  echo "$expr"
}

OUTPUT_DIR="/root/Audio_Separation_Pipeline/Filmes_Entrada/testing"
mkdir -p "$OUTPUT_DIR"

for ((i=1; i<=COUNT; i++)); do
  LAYOUT=${LAYOUTS[$RANDOM % ${#LAYOUTS[@]}]}
  DURATION=$((RANDOM % 600 + 600))
  FREQ=$((RANDOM % 800 + 200))

  OUTPUT="/root/Audio_Separation_Pipeline/Media/Filmes_Entrada/testing/placeholder_test${i}_${LAYOUT}.mp4"

  PAN=$(pan_expr "$LAYOUT")

  S=$((RANDOM % (DURATION / 2) + 1))
  T=$((RANDOM % (DURATION / 2) + 1))
  N=$((DURATION - S - T))

  if (( N < 1 )); then
    N=1
    T=$((DURATION - S - 1))
  fi

  echo "Gerando $OUTPUT | layout=$LAYOUT | duração=${DURATION}s | silêncio=${S}s | tom=${T}s | ruído=${N}s"

  ffmpeg -y \
    -f lavfi -i "color=c=blue:size=1280x720:rate=30:duration=${DURATION}" \
    -f lavfi -i "anullsrc=channel_layout=${LAYOUT}:sample_rate=48000" \
    -f lavfi -i "sine=frequency=${FREQ}:sample_rate=48000" \
    -f lavfi -i "anoisesrc=sample_rate=48000:color=white" \
    -filter_complex "
      [1]atrim=duration=${S}[silence];
      [2]pan=${PAN},atrim=duration=${T}[tone];
      [3]pan=${PAN},atrim=duration=${N}[noise];
      [silence][tone][noise]concat=n=3:v=0:a=1,
      atrim=duration=${DURATION},
      aformat=channel_layouts=${LAYOUT}[audio]
    " \
    -map 0:v \
    -map "[audio]" \
    -c:v h264_nvenc \
    -pix_fmt yuv420p \
    -c:a aac \
    -ar 48000 \
    -t "${DURATION}" \
    "$OUTPUT"

  echo "Gerado: $OUTPUT"
done

echo "$COUNT vídeos gerados."
