#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly VENV_DIR="$ROOT_DIR/.venv"

MODE="${1:-cpu}"  # cpu ou cuda

echo "[INFO] Root: $ROOT_DIR"
echo "[INFO] Mode: $MODE"

# cria venv se não existir
if [ ! -d "$VENV_DIR" ]; then
    echo "[INFO] Criando venv..."
    python3 -m venv "$VENV_DIR"
else
    echo "[INFO] Venv já existe"
fi

readonly PIP="$VENV_DIR/bin/pip"
readonly PY="$VENV_DIR/bin/python"
readonly DEMUCS="$VENV_DIR/bin/demucs"

echo "[INFO] Atualizando pip..."
"$PIP" install -U pip setuptools wheel

echo "[INFO] Instalando PyTorch stack..."

if [ "$MODE" = "cuda" ]; then
    echo "[INFO] Instalando CUDA (GPU)..."
    "$PIP" install torch torchaudio --index-url https://download.pytorch.org/whl/cu121
else
    echo "[INFO] Instalando CPU..."
    "$PIP" install torch torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

echo "[INFO] Instalando Demucs..."
"$PIP" install -U demucs

# torchcodec opcional (não quebra se falhar)
echo "[INFO] Instalando torchcodec (opcional)..."
"$PIP" install torchcodec || true

echo "[INFO] Testando Demucs..."
"$DEMUCS" --help >/dev/null

echo "[OK] Setup concluído"

echo
echo "Binários:"
echo "  Python: $PY"
echo "  Pip:    $PIP"
echo "  Demucs: $DEMUCS"
