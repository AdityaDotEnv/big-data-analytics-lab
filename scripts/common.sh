#!/usr/bin/env bash
# Shared helpers. Source this file from experiment runners.
set -Eeuo pipefail
LAB_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

require_cmd() {
  local cmd="$1" hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] Required command not found: $cmd"
    [[ -n "$hint" ]] && echo "        $hint"
    return 1
  fi
}

confirm() {
  local prompt="${1:-Continue?}"
  local answer
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

hadoop_env() {
  if [[ -n "${HADOOP_HOME:-}" && -x "$HADOOP_HOME/bin/hdfs" ]]; then
    export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
  elif [[ -x "$HOME/.local/opt/hadoop-3.4.3/bin/hdfs" ]]; then
    export HADOOP_HOME="$HOME/.local/opt/hadoop-3.4.3"
    export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HOME/.local/bin:$PATH"
  fi
  if ! command -v hadoop >/dev/null 2>&1 || ! command -v hdfs >/dev/null 2>&1; then
    echo "Hadoop is required for this experiment but was not detected."
    if confirm "Install Hadoop locally now?"; then
      "$LAB_ROOT/scripts/install-java.sh"
      "$LAB_ROOT/scripts/install-hadoop.sh"
      if [[ -x "$HOME/.local/opt/hadoop-3.4.3/bin/hadoop" ]]; then
        export HADOOP_HOME="$HOME/.local/opt/hadoop-3.4.3"
        export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HOME/.local/bin:$PATH"
      else
        local hadoop_real
        hadoop_real="$(readlink -f "$(command -v hadoop)")"
        export HADOOP_HOME="$(dirname "$(dirname "$hadoop_real")")"
      fi
    else
      echo "Install it later with: ./setup.sh --install hadoop"
      return 1
    fi
  fi
  require_cmd hadoop "Install Hadoop and configure PATH, or set HADOOP_HOME."
  require_cmd hdfs "HDFS CLI must be available."
}

mongo_env() {
  export MONGODB_URI="${MONGODB_URI:-mongodb://127.0.0.1:27017}"
  export LAB_DB_PREFIX="${LAB_DB_PREFIX:-bis701_lab}"
  if ! command -v mongosh >/dev/null 2>&1 || { [[ "$MONGODB_URI" == mongodb://127.0.0.1* || "$MONGODB_URI" == mongodb://localhost* ]] && ! command -v mongod >/dev/null 2>&1; }; then
    echo "MongoDB Shell and/or local MongoDB Server were not detected."
    if confirm "Install MongoDB Community Server and mongosh now?"; then
      "$LAB_ROOT/scripts/install-mongodb.sh"
    else
      echo "Install later with: ./setup.sh --install mongodb"
      return 1
    fi
  fi
  require_cmd mongosh "Install MongoDB Shell (mongosh)."
  if ! mongosh "$MONGODB_URI" --quiet --eval 'db.adminCommand({ping:1}).ok' >/dev/null 2>&1; then
    echo "[ERROR] MongoDB is not reachable at $MONGODB_URI"
    if command -v systemctl >/dev/null 2>&1 && confirm "Try starting the local mongod service?"; then
      if [[ "$EUID" -eq 0 ]]; then systemctl start mongod; else sudo systemctl start mongod; fi
    fi
  fi
  mongosh "$MONGODB_URI" --quiet --eval 'db.adminCommand({ping:1}).ok' >/dev/null
}
