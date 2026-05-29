# Pipeline de Separação de Voz com Demucs
Este projeto visa automatizar integralmente uma rotina de extração de diálogos de faixas dubladas, todas as etapas do fluxo são modulares e também podem ser executadas de forma independente.

A documentação completa se encontra em docs/. Este **README.md** comporta o *overview* do projeto. Informação especializada sobre os *scripts*, bibliotecas, arquivos de configuração e serviço são seções a parte.

## Estrutura
1. Reencode Padronizado e Downscale
2. Identificação e Organização por Layout de Áudio
3. Extração de Áudio - Mono & Stereo
4. Extração de Canais/Áudio - 6 & 8 Canais.
5. Separação de Diálogo com Demucs
6. Transferência de Arquivos de Saída para Produção

## Entrada de Arquivos
Arquivos são hospeados no Google Drive, montados via `rclone` em **Media/Filmes_Entrada** (diretórios criados com o script de instalação), esta etapa é configurada no ambiente de produção. 

Todos vídeos enviados ao Google Drive devem estar no caminho Filmes_Entrada, seguindo a estrutura abaixo:
#
  >- Filmes_Entrada
  >    - Filme_X
  >      - Filme_X_PT_BR.mp4
  >      - Filme_X_ENG.mp4
  >      - Filme_X_ESP.mkv
  >    - Filme_Y
  >      - Filme_Y_HI.mp4
  >      - Filme_Y_JP.mov
  >      - Filme_Y_RU.ts
#
Note que é esperado que os nomes dos arquivos não contenham espaços e caractéres especiais, o sistema consegue inferi-los e eliminar caracteres inválidos de qualquer maneira, mas é ideal manter um padrão.
Os códigos de idioma são apenas uma formalidade, não afetam em nada o funcionamento dos scripts, porém, como acontece com a convenção de nomenclatura de arquivos, é interessante manter um padrão fixo.

Por último, o sistema foi projetado para lidar apenas com os seguintes formatos de vídeo:
>  - .mp4
>  - .mkv
>  - .mov
>  - .ts

## Módulo 01 - Reencode Padronizado e Downscale
### Arquivos responsáveis:
> - [std_reencode.sh](scripts/std_reencode.sh)
> - [ffmpeg_config](config/ffmpeg_config)
#
Os arquivos nos formatos aceitos na pasta de entrada são processados pelo script da seguinte forma:
>- GPU Disponível = Todos arquivos são padronizados para .mp4 utilizando o codec `h264_nvenc`.
>- Fallback para CPU = Todos arquivos são padronizados para .mp4 utilizando o codec `libx264`.

Após o reencode de cada arquivo, o mesmo sofre um downscale para 480p, afim de reduzir o espaço ocupado e facilidade de download e importação em softwares de edção, visto que apenas o áudio é aproveitado na renderzação, o vídeo funciona como apoio visual para edição de áudio.
Ao final do processo, o arquivo é renomeado para contar com "_480p", como Filme_X_PT_BR_480p.mp4, com o intuito de indentificar arquivos processados e evitar que os mesmos entrem na fila novamente.
#
### Arquivos Problemáticos
Arquivos corrompidos ou com codecs que não estão na base de dados do *ffprobe" falham no processamento e recebem uma extensão de arquivo adicional ".corrupted" para indicar erro e evitar reprocessamento.
#
### Logging
Tudo que passa por este módulo, independente de sucesso ou falha, é registrado em **logs/std_reencode** (gerado pelo *script*). Todos logs deste projeto contam com a mesma estrutura de:
> Data - Caminho de Entrada - Status OK/ERRO - Caminho de Saída
#
## Módulo 02 - Identificação e Organização por Layout de Áudio

#

## Módulo 03 - Extração de Áudio - Mono & Stereo

#

## Módulo 04 - Extração de Canais/Áudio - 6 & 8 Canais

#

## Módulo 05 - Separação de Diálogo com Demucs

#

## Módulo 06 - Transferência de Arquivos de Saída para Produção
