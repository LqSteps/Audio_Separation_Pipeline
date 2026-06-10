# bin/: Binários e Executáveis Compilados

Esta seção documenta os executáveis pré-compilados inclusos no repositório, otimizados para aceleração de hardware.

## Conteúdo

### [ffmpeg](../bin/ffmpeg)
Build customizada do FFmpeg compilada estaticamente com suporte a aceleração CUDA.

- **Descrição:** Ferramenta de processamento multimídia para conversão, encoding, decodificação e manipulação de áudio/vídeo.
- **Tamanho:** ~29.7 MB
- **Compilação:** Build customizada com suporte a codecs CUDA para aceleração via GPU NVIDIA
- **Codecs incluídos:**
  - Vídeo: H.264 com `h264_nvenc` (aceleração CUDA via GPU NVIDIA)
  - Áudio: AAC, MP3, opus, FLAC, etc.
- **Uso no pipeline:** 
  - Reencoding de vídeos com aceleração GPU em `std_reencode.sh`
  - Extração de áudio em `extract_mono_stereo.sh`
  - Separação de canais em `split_multichannel.sh`
  - Geração de vídeos de teste com layout variado em `video_gen.sh`
- **Configuração:** Parâmetros de encoding definidos em `config/ffmpeg_config`
- **Documentação:** https://ffmpeg.org

### [ffprobe](../bin/ffprobe)
Utilitário do FFmpeg para inspeção de propriedades de arquivos multimídia (compilação estática).

- **Descrição:** Analisa e exibe informações detalhadas sobre streams de áudio, vídeo, codecs, layouts de canais, duração, bitrate, etc.
- **Tamanho:** ~29.2 MB
- **Compilação:** Build estática, sem dependências externas
- **Uso no pipeline:**
  - Detecção de layout de canais em `channel_layout_id.sh`
  - Verificação de propriedades de áudio antes do processamento
  - Diagnóstico de arquivos corrompidos ou sem streams de áudio
- **Documentação:** https://ffmpeg.org/ffprobe.html

---

## Detalhes Técnicos

### Aceleração CUDA (ffmpeg)

- **Requisito:** NVIDIA GPU com suporte a CUDA + NVIDIA driver instalado
- **Benefício:** Encoding em tempo real acelerado por hardware, reduzindo consumo de CPU em até 10x
- **Codec:** `h264_nvenc` disponível para reencoding de vídeos (480p)
- **Verificação:** `./bin/ffmpeg -encoders | grep nvenc` — lista codecs NVIDIA disponíveis
- **Performance:** Permite processar múltiplos vídeos simultaneamente sem sobrecarregar CPU

### Compilação Estática

Ambos os binários são compilados estaticamente, permitindo:
- Execução em diferentes ambientes Linux sem dependência de bibliotecas compartilhadas
- Portabilidade entre sistemas com glibc compatível
- Isolamento de dependências

---

## Comandos Úteis

```bash
# Listar codecs NVIDIA disponíveis
./bin/ffmpeg -encoders | grep nvenc

# Verificar informações completas do ffmpeg (incluindo configuração de build)
./bin/ffmpeg -version

# Exibir layout de canais de um arquivo
./bin/ffprobe -show_entries stream=channel_layout arquivo.mp4

# Listar todos os streams de um arquivo
./bin/ffprobe -show_streams arquivo.mp4

# Extrair apenas informações de áudio
./bin/ffprobe -select_streams a -show_entries stream=codec_name,channels arquivo.mp4

# Teste rápido de aceleração CUDA (cria arquivo dummy)
./bin/ffmpeg -f lavfi -i nullsrc=1x1 -f lavfi -i anullsrc=1:48000 -c:v h264_nvenc -t 1 -f null -
```

---

## Troubleshooting

### "CUDA not found" ou "h264_nvenc not available"
- Verificar driver NVIDIA: `nvidia-smi`
- Verificar acesso à GPU: `./bin/ffmpeg -f lavfi -i nullsrc=1x1 -f lavfi -i anullsrc=1:48000 -c:v h264_nvenc -t 1 -f null -`
- Se falhar, pode ser necessário recompilar ou usar fallback para CPU (modificar `config/ffmpeg_config`)

### Arquivo ou dependência corrompida
- Verificar permissões de execução: `chmod +x ./bin/ffmpeg ./bin/ffprobe`
- Testar binário: `./bin/ffmpeg -version`

### Performance baixa
- Verificar utilização de GPU: `nvidia-smi dmon` (em outra janela enquanto processando)
- Verificar se `h264_nvenc` está sendo utilizado nos logs do pipeline

