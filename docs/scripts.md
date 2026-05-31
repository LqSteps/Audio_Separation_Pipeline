# scripts/: Scripts Principais do Pipeline

Esta seção detalha cada script na ordem real de execução conforme definido em [start_pipeline.sh](../scripts/start_pipeline.sh):

## Ordem e Função

### 1. [std_reencode.sh](../scripts/std_reencode.sh)
Padroniza vídeos de entrada para H264 480p, usando o codec adaptativo do ambiente (`ffmpeg_config`).
- **Entrada:** Vídeos em vários formatos e resoluções em `$INPUT_DIR`.
- **Processo:** Reencoda todos arquivos para `*_480p.mp4` e preenche a fila de processamento.
- **Saída:** Apenas arquivos compatíveis são mantidos, originais removidos se sucesso. Log detalhado no `std_reencode.log`.
- **Erros:** Arquivos problemáticos são renomeados como `.corrupted` e removidos da fila.

### 2. [channel_layout_id.sh](../scripts/channel_layout_id.sh)
Identifica e separa vídeos conforme layout de canais de áudio.
- **Entrada:** Vídeos padronizados (`*_480p.mp4`) em `$INPUT_DIR`.
- **Processo:** Usa `ffprobe` para detectar layout de canais e move cada arquivo para pastas com nome do layout (e.g., `stereo`, `6_channels`).
- **Logging:** Mapeamento registrado em `channel_id.log`. Evita processar arquivos sem áudio.

### 3. [extract_mono_stereo.sh](../scripts/extract_mono_stereo.sh)
Converte vídeos mono, stereo e 3.0 para `.wav` no mesmo diretório.
- **Entrada:** Vídeos nas pastas separadas por layout.
- **Processo:** Usa `ffmpeg` e só processa arquivos que ainda não tem o `.wav`.
- **Erros:** Arquivos problemáticos/sem áudio são movidos para `.corrupted` e logados.

### 4. [split_multichannel.sh](../scripts/split_multichannel.sh)
Separa canais dos layouts 3.0 e 5.1 em arquivos `.wav` individuais.
- **Entrada:** Vídeos em `3_channels` e `6_channels`.
- **Processo:** Usa `ffmpeg -map_channel` para cada canal; output em subdiretórios `Canais_Separados`.
- **Logging:** Logs dedicados para 3 e 6 canais.

### 5. [demucs_split.sh](../scripts/demucs_split.sh)
Executa separação de fontes em `.wav` usando o Demucs, dentro da venv.
- **Entrada:** `.wav` não processados ainda (exceto os que já passaram pelo Demucs).
- **Processo:** Usa Demucs para separar stems, com detecção automática de sucesso/erro. Falhas vão para `Falhas_Demucs/`.
- **Logging:** Sucessos e falhas registrados em `demucs_split.log`.

### 6. [transfer_files.sh](../scripts/transfer_files.sh)
Sincroniza os resultados finais para o servidor via `rsync` sobre SSH.
- **Configuração:** Lê credenciais e destino do arquivo `network_config`.
- **Processo:** Só arquivos novos são enviados.
- **Importante:** Automatiza deploy de resultados e mantém integridade evitando duplicidade.

---

### Outros scripts utilitários

- [install_dependencies.sh](../scripts/install_dependencies.sh): Instala dependências do pipeline, executa configs necessárias, habilita serviço systemd.
- [venv.sh](../scripts/venv.sh): Cria/atualiza ambiente virtual Python para Demucs, instala PyTorch e dependências para CPU ou GPU.
- [start_pipeline.sh](../scripts/start_pipeline.sh): Orquestrador. Executa todos os scripts na sequência, garantindo fluxo íntegro.

---
> Todos os scripts dependem das funções utilitárias da pasta `libs/`. Veja [libs.md](./libs.md) para detalhes dos helpers chamados em cada etapa.
