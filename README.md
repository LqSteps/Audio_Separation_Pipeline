# Pipeline de Separação de Voz com Demucs
Este projeto visa automatizar integralmente uma rotina de extração de diálogos de faixas dubladas, todas as etapas do fluxo são modulares e também podem ser executadas de forma independente.

A documentação completa se encontra em docs/. Este **README.md** comporta o *overview* do projeto. Informação especializada sobre os *scripts*, bibliotecas, arquivos de configuração e serviço são seções a parte.

## Requisitos de Sistema
> Sistema Operacional: Linux
### Requisitos Mínimos de Sistema 
> 16GB de RAM\
> CPU Ryzen 5 5600 / Core i5-12400

*Para execução em hardware comercial, recomenda-se arquivos de duração menor ou que o usuário divida o arquivo em lotes.*


### Requisitos Recomendados de Sistema 
> 64GB DE RAM\
> CPU i5-13500 14 Core "Raptor Lake-S"\
> GPU RTX 4000 Ada Genaration ou similares

*Configurações testadas no ambiente de desenvolvimento, resultado satisfatório. A run completa de um arquivo leva de 4 à 10 minutos em qualidades inferiores (--shifts 1 à 3) e 40min a 1 horas (--shifts 10+) em maior qualidade, considerando média de 2h de duração das faixas de áudio.*

## Instruções de Uso

1. Clone e entre no repositório:
``` bash
git clone https://github.com/LqSteps/Audio_Separation_Pipeline.git && cd Audio_Separation_Pipeline 
```

2. Dê permissão de execução para o [instalador: scripts/install_dependencies.sh](scripts/install_dependencies.sh) com:

```bash
chmod +x scripts/install_dependencies.sh
```

3. Dê permissão de execução para o [instalador do ambiente python: scripts/venv.sh](scripts/venv.sh) com:

```bash
chmod +x scripts/venv.sh
```

4. Execute o [instalador do ambiente python](scripts/venv.sh) para instalação e ativação do ambiente do sistema com os pacotes necessários, como o Demucs.

``` bash
#Apenas CPU, execute:
./venv cpu

#GPU disponível, execute:
./venv gpu

# Passo crucial, dependendo da escolha, pacotes diferentes serão instalados para dar suporte à cada uma.
# Se sistemas sem GPU instalarem pacotes de GPU, o módulo de separação de voz não funcionará.
# Para sistemas com GPU, o usuário pode escolher instalar apenas dependências de CPU e utilizar o pipeline com processamento mais lento, embora o projeto conte com fallback integral para CPU se a placa de vídeo falhar ou não for detecada.
``` 

5. Execute o script para instalar dependências do *shell* e criar e habilitar o [arquivo de serviço](services/demucs_pipeline.service), que permite o *pipeline* rodar 24/7. 

6. Monte um Google Drive:Filmes_Entrada/ em **Media/Filmes_Entrada**.

7. Caso o sistema não esteja rodando, edite o arquivo de serviço e certifique-se de que o "**WorkingDir**" aponta para o caminho completo do diretório do repositório e "**Exec_Start**" aponte para o caminho absoluto de [start_pipeline.sh](scripts/start_pipeline.sh).

8. Acompanhe o progresso do demucs e a fila de processamento executando os seguintes scripts com sudo: [run_info/progress.sh](run_info/progress.sh) / [run_info/queue.sh](run_info/queue.sh)

>* O serviço pode ser desativado com ```systemctl stop demucs_pipeline```e executado manualmente a partir do [start_pipeline.sh](scripts/start_pipeline.sh).
## Estrutura
[start_pipeline.sh](scripts/start_pipeline.sh) executa os módulos na ordem apresentada. Porém, como dito anteriormente, uma das vantagens deste projeto é modularização completa, cada módulo pode ser executado fora do fluxo padrão e este script também pode ser alterado para atender à demandas diferentes..
1. Reencode Padronizado e Downscale

2. Identificação e Organização por Layout de Áudio
3. Extração de Áudio - Mono & Stereo
4. Extração de Canais/Áudio - 6 & 8 Canais.
5. Separação de Diálogo com Demucs
6. Transferência de Arquivos de Saída para Produção
## Entrada de Arquivos
Arquivos são hospedados no Google Drive, montados via `rclone` em **Media/Filmes_Entrada** (diretórios criados com o script de instalação), esta etapa é configurada no ambiente de produção. 

Todos vídeos enviados ao Google Drive devem estar no caminho Filmes_Entrada, seguindo a estrutura abaixo:
```text
Filmes_Entrada/
├── Filme_X/
│   ├── Filme_X_PT_BR.mp4
│   ├── Filme_X_ENG.mp4
│   └── Filme_X_ESP.mkv
│
└── Filme_Y/
    ├── Filme_Y_HI.mp4
    ├── Filme_Y_JP.mov
    └── Filme_Y_RU.ts
```
Note que é esperado que os nomes dos arquivos não contenham espaços e caractéres especiais, o sistema consegue inferi-los e eliminar caracteres inválidos de qualquer maneira, mas é ideal manter um padrão.
Os códigos de idioma são apenas uma formalidade, não afetam em nada o funcionamento dos scripts, porém, como acontece com a convenção de nomenclatura de arquivos, é interessante manter um padrão fixo.

Por último, o sistema foi projetado para lidar apenas com os seguintes formatos de vídeo:
>  - .mp4
>  - .mkv
>  - .mov
>  - .ts

## Módulo 01 - Reencode Padronizado e Downscale
#### Arquivos responsáveis:
>[std_reencode.sh](scripts/std_reencode.sh)\
>[ffmpeg_config](config/ffmpeg_config)
---
Os arquivos nos formatos aceitos na pasta de entrada são processados pelo script da seguinte forma:
>- GPU Disponível = Todos arquivos são padronizados para .mp4 utilizando o codec `h264_nvenc`.
>- Fallback para CPU = Todos arquivos são padronizados para .mp4 utilizando o codec `libx264`.

Após o reencode de cada arquivo, o mesmo sofre um downscale para 480p, afim de reduzir o espaço ocupado e facilidade de download e importação em softwares de edição, visto que apenas o áudio é aproveitado na renderização, o vídeo funciona como apoio visual para edição de áudio.

Ao final do processo, o arquivo é renomeado para contar com "_480p", como Filme_X_PT_BR_480p.mp4, com o intuito de identificar arquivos processados e evitar que os mesmos entrem na fila novamente.

---
### Arquivos Problemáticos
Arquivos corrompidos ou com codecs que não estão na base de dados do `ffprobe` falham no processamento e recebem uma extensão de arquivo adicional ".corrupted" para indicar erro e evitar reprocessamento.

---
### Logging
Tudo que passa por este módulo, independente de sucesso ou falha, é registrado em **logs/std_reencode** (gerado pelo *script*). Todos logs deste projeto contam com a mesma estrutura de:
> Data - Caminho de Entrada - Status OK/ERRO - Caminho de Saída

## Módulo 02 - Identificação e Organização por Layout de Áudio
#### Arquivos Responsáveis
>[channel_layout_id.sh](scripts/channel_layout_id.sh)
---
Arquivos **.mp4** com sufixo "_480p" localizados no diretório **Media/Filmes_Entrada/...** são organizados com base no seu *layout* de canais de áudio.

Devido ao fato de grande parte da mídia conter metadados quebrados e não possuir a informação do *layout*, utiliza-se o `ffprobe` para extrair apenas o número total de canais.

Em seguida, os arquivos são organizados em diretórios cujos nomes são derivados da forma que o `ffprobe` nomeia a quantidade de faixas, sendo:
>- mono
>- stereo
>- 3_channels
>- 6_channels -- (5.1, 5.1 side, 6.0 etc)
>- 8_channels -- (7.1 e variações)

**Nota-se que não há suporte para mídia com total de canais de áudio diferente da lista acima.**

---
### Estrutura de Saída de Arquivos
Os arquivos identificados corretamente são enviados à **Filmes_Saida/(número de canais)/Diretório do Arquivo**.

Segue abaixo a árvore de saída:

```text
Filmes_Saida/
├── mono/
│   ├── Filme_X/
│   │   ├── Filme_X_US_480p.mp4
│   │   ├── Filme_X_ES_480p.mp4
│   │   ├── Filme_X_JP_480p.mp4
│   │   └── Filme_X_DE_480p.mp4
│   │
│   └── Filme_Y/
│       ├── Filme_Y_FR_480p.mp4
│       ├── Filme_Y_BR_480p.mp4
│       ├── Filme_Y_IT_480p.mp4
│       └── Filme_Y_KR_480p.mp4
│
└── stereo/
    ├── Filme_X/
    │   ├── Filme_X_RU_480p.mp4
    │   ├── Filme_X_SA_480p.mp4
    │   ├── Filme_X_IN_480p.mp4
    │   └── Filme_X_TR_480p.mp4
    │
    └── Filme_Y/
        ├── Filme_Y_NL_480p.mp4
        ├── Filme_Y_PL_480p.mp4
        ├── Filme_Y_SE_480p.mp4
        └── Filme_Y_CZ_480p.mp4
```
### Arquivos Problemáticos
Arquivos sem áudio logicamente não são processados e permanecem na pasta de entrada.

### Logging
Registros de entrada e saída ficam disponíveis em **logs/channel_id.log**.

## Módulo 03 - Extração de Áudio - Mono & Stereo
#### Arquivos responsáveis
>[extract_mono_stereo.sh](scripts/extract_mono_stereo.sh)
---
Lê qualquer arquivo **.mp4** presente nos  [diretórios mono/stereo de saída do Módulo 02](#estrutura-de-saída-de-arquivos) e extrai o áudio para um novo arquivo de mesmo nome e no mesmo diretório, seguindo os seguintes parâmetros:
> Codec: pcm_f32le - Formato: .wav

Portanto, padroniza-se todos os áudios para evitar discrepância e resultados inesperados no [Módulo 05](#módulo-05---separação-de-diálogo-com-demucs)

---
### Estrutura de Saída de Arquivos
```text
Filmes_Saida/
├── mono/
│   ├── Filme_X/
│   │   ├── Filme_X_US_480p.mp4
│   │   ├── Filme_X_US_480p.wav
│   │   ├── Filme_X_ES_480p.mp4
│   │   ├── Filme_X_ES_480p.wav
│   │   ├── Filme_X_JP_480p.mp4
│   │   ├── Filme_X_JP_480p.wav
│   │   ├── Filme_X_DE_480p.mp4
│   │   └── Filme_X_DE_480p.wav
│   │
│   └── Filme_Y/
│       ├── Filme_Y_FR_480p.mp4
│       ├── Filme_Y_FR_480p.wav
│       ├── Filme_Y_BR_480p.mp4
│       ├── Filme_Y_BR_480p.wav
│       ├── Filme_Y_IT_480p.mp4
│       ├── Filme_Y_IT_480p.wav
│       ├── Filme_Y_KR_480p.mp4
│       └── Filme_Y_KR_480p.wav
│
└── stereo/
    ├── Filme_X/
    │   ├── Filme_X_RU_480p.mp4
    │   ├── Filme_X_RU_480p.wav
    │   ├── Filme_X_SA_480p.mp4
    │   ├── Filme_X_SA_480p.wav
    │   ├── Filme_X_IN_480p.mp4
    │   ├── Filme_X_IN_480p.wav
    │   ├── Filme_X_TR_480p.mp4
    │   └── Filme_X_TR_480p.wav
    │
    └── Filme_Y/
        ├── Filme_Y_NL_480p.mp4
        ├── Filme_Y_NL_480p.wav
        ├── Filme_Y_PL_480p.mp4
        ├── Filme_Y_PL_480p.wav
        ├── Filme_Y_SE_480p.mp4
        ├── Filme_Y_SE_480p.wav
        ├── Filme_Y_CZ_480p.mp4
        └── Filme_Y_CZ_480p.wav
```
---
### Arquivos Problemáticos
Aplica-se a mesma lógica do [Módulo 01](#arquivos-problemáticos).

---
### Logging
Registros de entrada e saída mono ficam disponíveis em **logs/mono_wav.log**.\
Registros de entrada e saída stereo ficam disponíveis em **logs/stereo_wav.log**.

## Módulo 04 - Extração de Canais/Áudio - 6 & 8 Canais
#### Arquivos Responsáveis
> [split_multichannel.sh](scripts/split_multichannel.sh)
---
Lê qualquer arquivo **.mp4** presente nos  [diretórios 3_channels/6_channels de saída do Módulo 02](#estrutura-de-saída-de-arquivos) e extrai os canais de áudio como arquivos **.wav** separados no subdiretório **Canais_Separados**.

O canal **FC** (*front central*) sempre contém a maior quantidade de informação referente à diálogos, mas os outros canais também podem ser aproveitados na edição para reconstrução de partes perdidas no **FC**.

### Estrutura de Saída de Arquivos

```text
Filmes_Saida/
├── 3_channels/
│   ├── Filme_X/
│   │   ├── Filme_X_US_480p.mp4
│   │   ├── Filme_X_ES_480p.mp4
│   │   ├── Filme_X_JP_480p.mp4
│   │   └── Canais_Separados/
│   │       ├── Filme_X_US_480p/
│   │       │   ├── FL.wav
│   │       │   ├── FR.wav
│   │       │   └── FC.wav
│   │       ├── Filme_X_ES_480p/
│   │       │   ├── FL.wav
│   │       │   ├── FR.wav
│   │       │   └── FC.wav
│   │       └── Filme_X_JP_480p/
│   │           ├── FL.wav
│   │           ├── FR.wav
│   │           └── FC.wav
│   │
│   └── Filme_Y/
│       ├── Filme_Y_BR_480p.mp4
│       ├── Filme_Y_FR_480p.mp4
│       ├── Filme_Y_IT_480p.mp4
│       └── Canais_Separados/
│           ├── Filme_Y_BR_480p/
│           │   ├── FL.wav
│           │   ├── FR.wav
│           │   └── FC.wav
│           ├── Filme_Y_FR_480p/
│           │   ├── FL.wav
│           │   ├── FR.wav
│           │   └── FC.wav
│           └── Filme_Y_IT_480p/
│               ├── FL.wav
│               ├── FR.wav
│               └── FC.wav
│
└── 6_channels/
    ├── Filme_X/
    │   ├── Filme_X_RU_480p.mp4
    │   ├── Filme_X_DE_480p.mp4
    │   ├── Filme_X_TR_480p.mp4
    │   └── Canais_Separados/
    │       ├── Filme_X_RU_480p/
    │       │   ├── FL.wav
    │       │   ├── FR.wav
    │       │   ├── FC.wav
    │       │   ├── LFE.wav
    │       │   ├── SL.wav
    │       │   └── SR.wav
    │       ├── Filme_X_DE_480p/
    │       │   ├── FL.wav
    │       │   ├── FR.wav
    │       │   ├── FC.wav
    │       │   ├── LFE.wav
    │       │   ├── SL.wav
    │       │   └── SR.wav
    │       └── Filme_X_TR_480p/
    │           ├── FL.wav
    │           ├── FR.wav
    │           ├── FC.wav
    │           ├── LFE.wav
    │           ├── SL.wav
    │           └── SR.wav
    │
    └── Filme_Y/
        ├── Filme_Y_KR_480p.mp4
        ├── Filme_Y_PL_480p.mp4
        ├── Filme_Y_NL_480p.mp4
        └── Canais_Separados/
            ├── Filme_Y_KR_480p/
            │   ├── FL.wav
            │   ├── FR.wav
            │   ├── FC.wav
            │   ├── LFE.wav
            │   ├── SL.wav
            │   └── SR.wav
            ├── Filme_Y_PL_480p/
            │   ├── FL.wav
            │   ├── FR.wav
            │   ├── FC.wav
            │   ├── LFE.wav
            │   ├── SL.wav
            │   └── SR.wav
            └── Filme_Y_NL_480p/
                ├── FL.wav
                ├── FR.wav
                ├── FC.wav
                ├── LFE.wav
                ├── SL.wav
                └── SR.wav
```

>*Suporte para arquivos de 8 canais em desenvolvimento.*

### Arquivos Problemáticos
Aplica-se a mesma lógica do [Módulo 01](#arquivos-problemáticos).

### Logging
Registros de sucessos e falhas para **3_channels** ficam disponíveis em **logs/extrair_3_canais.log**.\
Registros de sucessos e falhas para **6_channels** ficam disponíveis em **logs/extrair_6_canais.log**.\

## Módulo 05 - Separação de Diálogo com Demucs
#### Arquivos Responsáveis
>[demucs_split.sh](scripts/demucs_split.sh)

Usa de entrada todos os arquivos **.wav** disponíveis recursivamente nos diretórios **mono/stereo** e apenas os arquivos **FC.wav** em **3_channels/6_channels**.

Para cada *input*, utiliza-se o Demucs para extrair diálogos da faixa de áudio, além de ruídos, instrumentos etc.

> *Outras faixas geradas pelo Demucs, como **other.wav** podem conter áudio relevante para auxiliar no processo de edição, que ainda que não sejam diálogos, podem ajudar a reconstruir o áudio completo da faixa e promover maior detalhamento.*

### Estrutura de Saída de Arquivos

Logo abaixo consta a árvore de diretórios de saída deste módulo, em suma, os caminhos de saída dos módulos de extração de áudio recebem os subdiretórios Stems/ e Falhas_Demucs:

```text
Filmes_Saida/
├── stereo/
│   └── Filme_X/
│       ├── Filme_X_US_480p.mp4
│       ├── Filme_X_US_480p.wav
│       ├── Filme_X_ES_480p.mp4
│       ├── Filme_X_ES_480p.wav
│       ├── Filme_X_JP_480p.mp4
│       ├── Filme_X_JP_480p.wav
│       ├── Falhas_Demucs/
│       │   └── Filme_X_JP_480p.wav     <- falhou, realocado
│       └── Stems/
│           └── htdemucs/
│               ├── Filme_X_US_480p/
│               │   ├── vocals.wav
│               │   ├── drums.wav
│               │   ├── bass.wav
│               │   └── other.wav
│               └── Filme_X_ES_480p/
│                   ├── vocals.wav
│                   ├── drums.wav
│                   ├── bass.wav
│                   └── other.wav
│
└── 6_channels/
    └── Filme_Y/
        └── Canais_Separados/
            ├── Filme_Y_BR_480p/
            │   ├── FL.wav
            │   ├── FR.wav
            │   ├── FC.wav
            │   ├── LFE.wav
            │   ├── SL.wav
            │   ├── SR.wav
            │   ├── Falhas_Demucs/
            │   │   └── FC.wav          <- falhou, realocado
            │   └── Stems/
            │       └── htdemucs/
            │           └── FC/
            │               ├── vocals.wav
            │               ├── drums.wav
            │               ├── bass.wav
            │               └── other.wav
            └── Filme_Y_FR_480p/
                ├── FL.wav
                ├── FR.wav
                ├── FC.wav
                ├── LFE.wav
                ├── SL.wav
                ├── SR.wav
                └── Stems/
                    └── htdemucs/
                        └── FC/
                            ├── vocals.wav
                            ├── drums.wav
                            ├── bass.wav
                            └── other.wav
```

### Arquivos Problemáticos

Faixas de áudio que o Demucs não conseguiu processar ou causaram *crash* no sistema são enviadas para **Falhas_Demucs** de acordo com a [estrutura de saída de arquivos do Módulo 04](#estrutura-de-saída-de-arquivos-3).

Isto ocorre para evitar o sistema entrar em um *loop* de processamento de faixas que o *script* não consegue processar, visto que ele não busca arquivos neste caminho.

### Logging
Registros de sucessos e falhas ficam em **logs/demucs_split.log**.
## Módulo 06 - Transferência de Arquivos de Saída para Produção
#### Arquivos Responsáveis
>[transfer_files.sh](scripts/transfer_files.sh)\
>[network_config](config/network_config)

Transferência de qualquer arquivo **.mp4** ou **.wav** presentes em **Media/Filmes_Saida. Utiliza-se o `rsync`com a opção de nunca enviar novamente o arquivo se ele não for modificado na origem.

O destino final é o ambiente de produção da edição, em:
> <IP_PRODUÇÃO>>:/mnt/16tb/Audio_Separation_Pipeline/Media/Filmes_Saida

## Próximos Passos
- Adicionar suporte à arquivos de 8 canais.
- Implementar paralelismo no [Módulo 06 - Transferências](#módulo-06---transferência-de-arquivos-de-saída-para-produção), para que seja executado 24/7 sem depender da ordem corrente do *pipeline*.
