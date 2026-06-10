# run_info/: Monitoramento em Tempo Real

Scripts para monitorar e acompanhar o status do pipeline durante a execução.

## Scripts de Monitoramento

### [full_info.sh](../run_info/full_info.sh)
Dashboard completo em tmux que exibe simultaneamente fila, progresso e logs do pipeline.

- **Uso:** `bash ./run_info/full_info.sh`
- **Dependências:** `tmux`, `docker-compose`
- **Funcionalidade:**
  - Mata qualquer sessão tmux prévia chamada `main`
  - Cria uma nova sessão tmux com 3 painéis distribuídos:
    - Painel superior esquerdo: Fila de processamento (`queue.sh`)
    - Painel superior direito: Progresso em tempo real do Demucs (`progress.sh`)
    - Painel inferior: Logs do Docker Compose (`docker compose logs -f`)
  - Anexa a sessão ao terminal para visualização interativa
- **Atalhos tmux úteis:**
  - `Ctrl+b` + `o`: Mover entre painéis
  - `Ctrl+b` + `d`: Desanexar sessão
  - `Ctrl+b` + `c`: Criar nova janela
  - `Ctrl+b` + `x`: Fechar painel ativo
- **Exemplo:** Execute no terminal e acompanhe o pipeline em 3 pontos de vista simultaneamente

### [progress.sh](../run_info/progress.sh)
Monitora o arquivo atual e progresso do Demucs em tempo real.

- **Uso:** `sudo bash ./run_info/progress.sh`
- **Permissões:** Requer `sudo` (necessário para ler arquivos do Demucs)
- **Dependências:** `watch`, `gpustat` (para visualizar status GPU)
- **Refresh:** Atualiza a cada 3 segundos
- **Output:**
  - Arquivo atual sendo processado (lido de `$BASE_DIR/tmp/current_file_demucs.txt`)
  - Progresso do processamento (lido de `$BASE_DIR/tmp/current_progress_demucs.txt`)
  - Status em tempo real da GPU (via `gpustat`)
- **Utilidade:** Verificar se o Demucs está progredindo, detectar travamentos ou erros

### [queue.sh](../run_info/queue.sh)
Exibe a fila de arquivos aguardando processamento.

- **Uso:** `bash ./run_info/queue.sh`
- **Permissões:** Sem permissões especiais necessárias
- **Dependências:** `watch`
- **Refresh:** Atualiza a cada 1 segundo
- **Output:** Conteúdo de `$BASE_DIR/tmp/file_queue.txt` com a lista de arquivos na fila
- **Utilidade:** Acompanhar lotes de processamento, detectar gargalos ou arquivos presos

---

## Fluxo de Uso Recomendado

1. **Para monitoramento completo:** Use `full_info.sh` para ver tudo simultaneamente
2. **Para diagnóstico isolado:**
   - `queue.sh` — verificar se há arquivos enfileirados
   - `progress.sh` — verificar se o Demucs está processando
   - `docker compose logs -f` — diagnosticar erros de container

---

## Notas Importantes

- **Arquivos temporários:** O progresso é rastreado via arquivos em `$BASE_DIR/tmp/`. Se não existirem, o monitoring exibirá vazio até o primeiro arquivo ser processado.
- **GPU:** `gpustat` mostra status da GPU NVIDIA. Verifique se CUDA está configurado e acessível.
- **Permissões sudo em `progress.sh`:** Necessário para ler arquivos criados pelo serviço systemd (que roda como root ou sistema).

