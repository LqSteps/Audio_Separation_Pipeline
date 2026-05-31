# libs/: Funções Utilitárias

Coleção de scripts reaproveitados em todo o pipeline:

- **[color_output.sh](../libs/color_output.sh):** Define variáveis e funções para saída colorida no terminal, melhorando mensagens e logs visuais.
- **[pathing.sh](../libs/pathing.sh):** Centraliza variáveis de diretórios (`$BASE_DIR`, `$MEDIA_DIR` etc), garantindo consistência de paths.
- **[queue_tracker.sh](../libs/queue_tracker.sh):** Função para remover arquivos da fila de processamento, garantindo que arquivos processados/descartados não sejam reprocessados.
- **[quick_log.sh](../libs/quick_log.sh):** Funções `log_ok` e `log_erro` para registrar, respectivamente, sucessos e falhas a cada etapa, com detalhes configuráveis.

Cada script dos `scripts/` importa essas funções conforme necessário para automatizar paths, logs, gestão de filas e mensagens.

---
> Veja a documentação in-file de cada script para entender usos em pontos específicos do pipeline.
