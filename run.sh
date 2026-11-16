#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Big Data Analytics Lab launcher

Usage:
  ./run.sh                 Interactive experiment menu
  ./run.sh --check         Check installed dependencies
  ./run.sh --install all   Install all dependencies
  ./run.sh 1..6            Run one experiment directly
EOF
}

chmod +x "$ROOT"/setup.sh "$ROOT"/install.sh "$ROOT"/experiments/*/run.sh "$ROOT"/scripts/*.sh 2>/dev/null || true

experiments=(
  "01-hadoop-installation|Hadoop installation and configuration"
  "02-hdfs-file-management|HDFS file management"
  "03-mapreduce-wordcount|MapReduce Word Count"
  "04-mongodb-crud|MongoDB basics and CRUD"
  "05-mongodb-queries-arrays|MongoDB queries, NULL and arrays"
  "06-mongodb-aggregation|MongoDB aggregation"
)

case "${1:-}" in
  --help|-h) usage; exit 0 ;;
  --check) exec "$ROOT/setup.sh" --check ;;
  --install) exec "$ROOT/setup.sh" --install "${2:-all}" ;;
  [1-6])
    IFS='|' read -r dir title <<< "${experiments[$(( $1 - 1 ))]}"
    exec "$ROOT/experiments/$dir/run.sh"
    ;;
  "") ;;
  *) usage >&2; exit 2 ;;
esac

while true; do
  echo
  echo "========================================"
  echo "       BIG DATA ANALYTICS LAB"
  echo "========================================"
  for i in "${!experiments[@]}"; do
    IFS='|' read -r dir title <<< "${experiments[$i]}"
    printf "  %d) %s\n" "$((i+1))" "$title"
  done
  echo "  7) Check environment"
  echo "  8) Install all dependencies"
  echo "  0) Exit"
  read -r -p "Select an option: " choice
  case "$choice" in
    0) echo "Goodbye."; exit 0 ;;
    7) "$ROOT/setup.sh" --check ;;
    8) "$ROOT/setup.sh" --install all ;;
    [1-6])
      IFS='|' read -r dir title <<< "${experiments[$((choice-1))]}"
      echo
      echo "Launching: $title"
      "$ROOT/experiments/$dir/run.sh"
      ;;
    *) echo "Invalid selection." ;;
  esac
done
