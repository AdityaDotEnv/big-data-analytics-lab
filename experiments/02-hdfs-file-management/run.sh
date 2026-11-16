#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../scripts/common.sh"
hadoop_env
require_cmd hdfs
if ! hdfs dfs -ls / >/dev/null 2>&1; then
  echo "[ERROR] HDFS is not reachable. Start your configured NameNode/DataNode first."
  exit 1
fi

HDFS_DIR="/user/${USER}/bcs714d-lab-hdfs"
LOCAL_FILE="$HERE/data/sample.txt"
echo "Experiment 2: HDFS file management"
echo "Creating $HDFS_DIR"
hdfs dfs -mkdir -p "$HDFS_DIR/input"
hdfs dfs -put -f "$LOCAL_FILE" "$HDFS_DIR/input/sample.txt"

echo; echo "1. List files:"
hdfs dfs -ls -R "$HDFS_DIR"
echo; echo "2. Read file:"
hdfs dfs -cat "$HDFS_DIR/input/sample.txt"
echo; echo "3. Copy within HDFS:"
hdfs dfs -cp "$HDFS_DIR/input/sample.txt" "$HDFS_DIR/sample-copy.txt"
hdfs dfs -ls "$HDFS_DIR"
echo; echo "4. Download file:"
DEST="${TMPDIR:-/tmp}/bcs714d-hdfs-download-${USER}.txt"
hdfs dfs -get -f "$HDFS_DIR/sample-copy.txt" "$DEST"
echo "Downloaded to: $DEST"
cat "$DEST"
echo
if confirm "Delete this experiment's HDFS directory ($HDFS_DIR)?"; then
  hdfs dfs -rm -r -f "$HDFS_DIR"
  echo "Experiment HDFS directory removed."
else
  echo "Keeping HDFS files at $HDFS_DIR"
fi
