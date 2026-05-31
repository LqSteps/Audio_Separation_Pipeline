#!/bin/bash

LAYOUTS=("mono" "stereo" "3.0" "5.1" "7.1")
COUNT=${1:-5}

channels() {
  case $1 in
    mono)   echo 1 ;;
    stereo) echo 2 ;;
    3.0)    echo 3 ;;
    5.1)    echo 6 ;;
    7.1)    echo 8 ;;
  esac
}

pan_expr() {
  local layout=$1
  local ch=$(channels $layout)
  local expr="$layout|"
  for j in $(seq 0 $((ch - 1))); do
    expr+="c${j}=c0"
    [ $j -lt $((ch - 1)) ] && expr+="|"
  done
  echo "$expr"
}

for i in $(seq 1 $COUNT); do
  LAYOUT=${LAYOUTS[$RANDOM % ${#LAYOUTS[@]}]}
  DURATION=$((RANDOM % 20 + 5))
  FREQ=$((RANDOM % 800 + 200))
  OUTPUT="/home/lqs/Desktop/Audio_Separation_Pipeline/Media/Filmes_Entrada/testing/placeholder_${i}_${LAYOUT}.mp4"
  CH=$(channels $LAYOUT)
  PAN=$(pan_expr $LAYOUT)

  S=$((RANDOM % (DURATION / 2) + 1))
  T=$((RANDOM % (DURATION / 2) + 1))
  N=$((DURATION - S - T))
  [ $N -lt 1 ] && N=1 && T=$((DURATION - S - 1))

  echo "Gerando $OUTPUT | layout: $LAYOUT ($CH ch) | duracao: ${DURATION}s | silencio: ${S}s | tom: ${T}s | ruido: ${N}s"

  ffmpeg -y \
    -f lavfi -i "color=c=blue:size=1280x720:rate=30:duration=$DURATION" \
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
    -vf "drawtext=text='${LAYOUT} | ${DURATION}s':fontsize=40:fontcolor=white:x=20:y=20,
         drawtext=text='silence=${S}s tone=${T}s noise=${N}s':fontsize=28:fontcolor=yellow:x=20:y=70" \
    -map 0:v -map "[audio]" \
    -c:v libx264 -c:a aac \
    -t $DURATION \
    "$OUTPUT"

  echo "Gerado: $OUTPUT"
done

echo "$COUNT videos gerados."
