#!/usr/bin/env bash
set -euo pipefail
VERSION="${SPARK_VERSION:-3.5.7}"
ROOT="${BIGDATA_HOME:-$HOME/.local/opt}"
mkdir -p "$ROOT" "$HOME/.local/bin"
ARCHIVE="/tmp/spark-${VERSION}-bin-hadoop3.tgz"
URL="https://archive.apache.org/dist/spark/spark-${VERSION}/spark-${VERSION}-bin-hadoop3.tgz"
command -v curl >/dev/null || { echo "Install curl first: sudo apt install curl"; exit 1; }
echo "Downloading Apache Spark ${VERSION} (Hadoop 3 build)..."
curl -fL --retry 3 "$URL" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$ROOT"
ln -sfn "$ROOT/spark-${VERSION}-bin-hadoop3" "$ROOT/spark"
ln -sfn "$ROOT/spark/bin/spark-submit" "$HOME/.local/bin/spark-submit"
ln -sfn "$ROOT/spark/bin/spark-shell" "$HOME/.local/bin/spark-shell"
if ! grep -q 'SPARK_HOME' "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport SPARK_HOME="$HOME/.local/opt/spark"\nexport PATH="$SPARK_HOME/bin:$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
fi
export SPARK_HOME="$ROOT/spark"; export PATH="$SPARK_HOME/bin:$HOME/.local/bin:$PATH"
echo "Spark installed at $SPARK_HOME"
spark-submit --version
echo "Open a new terminal or run: source ~/.bashrc"
