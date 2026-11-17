#!/usr/bin/env bash
set -euo pipefail
VERSION="${HIVE_VERSION:-4.0.1}"
ROOT="${BIGDATA_HOME:-$HOME/.local/opt}"
mkdir -p "$ROOT" "$HOME/.local/bin"
ARCHIVE="/tmp/apache-hive-${VERSION}-bin.tar.gz"
URL="https://archive.apache.org/dist/hive/hive-${VERSION}/apache-hive-${VERSION}-bin.tar.gz"
command -v curl >/dev/null || { echo "Install curl first: sudo apt install curl"; exit 1; }
echo "Downloading Apache Hive ${VERSION}..."
curl -fL --retry 3 "$URL" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$ROOT"
ln -sfn "$ROOT/apache-hive-${VERSION}-bin" "$ROOT/hive"
ln -sfn "$ROOT/hive/bin/beeline" "$HOME/.local/bin/beeline"
ln -sfn "$ROOT/hive/bin/schematool" "$HOME/.local/bin/schematool"
if ! grep -q 'HIVE_HOME' "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport HIVE_HOME="$HOME/.local/opt/hive"\nexport PATH="$HIVE_HOME/bin:$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
fi
export HIVE_HOME="$ROOT/hive"; export PATH="$HIVE_HOME/bin:$HOME/.local/bin:$PATH"
echo "Hive installed at $HIVE_HOME"
echo "Hive 4 uses Beeline for HiveServer2 connections. Configure metastore and HiveServer2 before running Experiment 7."
beeline --version || true
echo "Open a new terminal or run: source ~/.bashrc"
