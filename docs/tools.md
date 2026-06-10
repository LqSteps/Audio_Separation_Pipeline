# tools/: Ferramentas Utilitárias e de Manutenção

Esta seção detalha as ferramentas de suporte para manutenção, testes e operação do pipeline.

## Ferramentas Disponíveis

### [purge_old_files.sh](../tools/purge_old_files.sh)
Remove automaticamente vídeos e arquivos de áudio antigos para liberar espaço em disco.

- **Permissões:** Requer privilégios de root (`sudo`)
- **Uso:** `sudo ./tools/purge_old_files.sh <DIAS>`
  - `<DIAS>`: Número de dias. Remove arquivos modificados há mais de X dias.
- **Formatos processados:** `.mp4`, `.mp3`, `.wav`, `.aac`, `.ts`
- **Caminho alvo:** `/Audio_Separation_Pipeline/Media` e subdiretórios
- **Output:** 
  - Relatório de arquivos deletados no stdout
  - Espaço liberado
  - Espaço atual do disco
  - Log completo em `logs/deleted_files.log`
- **Exemplo:** `sudo ./tools/purge_old_files.sh 30` — remove arquivos com mais de 30 dias

### [video_gen.sh](../tools/video_gen.sh)
Gera vídeos de teste sintéticos com diferentes layouts de áudio para validação e debugging do pipeline.

- **Uso:** `./tools/video_gen.sh [QUANTIDADE]`
  - `[QUANTIDADE]`: Número de vídeos a gerar (padrão: 2)
- **Características de cada vídeo:**
  - Duração aleatória (600-1200 segundos, ~10-20 minutos)
  - Sequência aleatória de: silêncio → tom senoidal → ruído branco
  - Layouts de áudio variados (mono, stereo, 5.1, etc.)
  - Resolução: 1280x720 (HD)
  - Frame rate: 30 FPS
  - Codecs: H.264 com `h264_nvenc` (vídeo), AAC (áudio)
  - Taxa de amostragem: 48kHz
- **Output:** Vídeos em `/root/Audio_Separation_Pipeline/Filmes_Entrada/testing/`
  - Nomenclatura: `placeholder_test<N>_<LAYOUT>.mp4`
- **Dependência:** FFmpeg com suporte a `h264_nvenc` (build CUDA customizada incluída em `bin/ffmpeg`)
- **Exemplo:** `./tools/video_gen.sh 5` — gera 5 vídeos de teste
- **Uso recomendado:**
  - Validação de pipeline após novo deploy
  - Testes de regressão sem material sensível
  - Desenvolvimento e debugging local
  - Teste de novos formatos/layouts antes de processar arquivo real

---

## Notas Importantes

- **Espaço em disco:** Use `purge_old_files.sh` regularmente em ambientes de produção para evitar preenchimento de disco.
- **Testes:** Execute `video_gen.sh` antes de testar o pipeline com novos builds ou mudanças estruturais.
- **Logs:** Todos os eventos de deleção são registrados em `logs/deleted_files.log` para auditoria.
- **Aceleração GPU:** `video_gen.sh` usa `h264_nvenc` por padrão. Verifique se NVIDIA GPU está disponível.

