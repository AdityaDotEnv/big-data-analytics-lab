#!/usr/bin/env bash
set -euo pipefail
VERSION="${PIG_VERSION:-0.17.0}"
ROOT="${BIGDATA_HOME:-$HOME/.local/opt}"
mkdir -p "$ROOT" "$HOME/.local/bin"
ARCHIVE="/tmp/pig-${VERSION}.tar.gz"
URL="https://archive.apache.org/dist/pig/pig-${VERSION}/pig-${VERSION}.tar.gz"
command -v curl >/dev/null || { echo "Install curl first: sudo apt install curl"; exit 1; }
echo "Downloading Apache Pig ${VERSION}..."
curl -fL --retry 3 "$URL" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$ROOT"
ln -sfn "$ROOT/pig-${VERSION}" "$ROOT/pig"
ln -sfn "$ROOT/pig/bin/pig" "$HOME/.local/bin/pig"
if ! grep -q 'PIG_HOME' "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport PIG_HOME="$HOME/.local/opt/pig"\nexport PATH="$PIG_HOME/bin:$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
fi
export PIG_HOME="$ROOT/pig"; export PATH="$PIG_HOME/bin:$HOME/.local/bin:$PATH"
echo "Pig installed at $PIG_HOME"
pig -version || true
echo "Open a new terminal or run: source ~/.bashrc"
