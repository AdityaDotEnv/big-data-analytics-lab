#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../scripts/common.sh"
hadoop_env
require_cmd java "Install a JDK."
require_cmd mvn "Install Maven (sudo apt install maven)."

OUT="/user/${USER}/bcs714d-wordcount-output"
IN="/user/${USER}/bcs714d-wordcount-input"
JAR="$HERE/target/wordcount-1.0.0.jar"

if ! hdfs dfs -ls / >/dev/null 2>&1; then
  echo "[ERROR] HDFS is not reachable. Start HDFS/YARN as appropriate."
  exit 1
fi

HADOOP_VERSION_DETECTED="$(hadoop version 2>/dev/null | awk 'NR==1 {print $2}')"
if [[ -z "$HADOOP_VERSION_DETECTED" ]]; then
  echo "[ERROR] Could not determine installed Hadoop version."; exit 1
fi
echo "Building MapReduce program against Hadoop $HADOOP_VERSION_DETECTED..."
(cd "$HERE" && mvn -q -DskipTests -Dhadoop.version="$HADOOP_VERSION_DETECTED" package)

echo "Preparing HDFS input..."
hdfs dfs -mkdir -p "$IN"
hdfs dfs -put -f "$HERE/data/input.txt" "$IN/input.txt"

if hdfs dfs -test -e "$OUT"; then
  if confirm "Output $OUT already exists. Remove this experiment output and rerun?"; then
    hdfs dfs -rm -r "$OUT"
  else
    echo "Aborted to preserve existing output."; exit 1
  fi
fi

echo "Running Word Count..."
hadoop jar "$JAR" "$IN" "$OUT"
echo
echo "Word count output:"
hdfs dfs -cat "$OUT/part-r-00000"
