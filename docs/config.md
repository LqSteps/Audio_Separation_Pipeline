# config/: Configuração do Ambiente

Scripts que garantem adaptação automática do pipeline conforme onde está rodando.

- **[ffmpeg_config](../config/ffmpeg_config):** Seleciona o codec certo baseado no hostname (`h264_nvenc` para produção/GPU, `libx264` para dev-local). Importado dinamicamente pelos scripts de encode.
- **[network_config](../config/network_config):** Define a variável de destino SSH (`SSH_AGENT`), trocando endereço/usuário conforme ambiente.
- **[systemd_config](../config/systemd_config):** Aplica overrides para o systemd garantindo que o serviço rode sempre no path correto e reinicialize a cada alteração/configuração.

Esses arquivos são sempre importados ou executados automaticamente pelos scripts principais para garantir que diferenças de ambiente não quebrem o pipeline de produção.

---
> Reconfigure configurações, hosts e ambientes sempre que migrar ou clonar o repositório.
