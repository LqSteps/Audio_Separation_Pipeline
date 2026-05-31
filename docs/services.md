# services/: Integração com systemd

- **[demucs_pipeline.service](../services/demucs_pipeline.service):** Arquivo de unidade para systemd, responsável por rodar, reiniciar e manter o pipeline sempre ativo e operante.
- Pode ser instalado automaticamente por `install_dependencies.sh` ou manualmente via symlink.
- Permite visualizar logs via `journalctl`, e garante restart em caso de falhas.

---
> Lembre-se de `sudo systemctl enable/start demucs_pipeline.service` após configuração.
