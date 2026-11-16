#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../scripts/common.sh"

echo "Experiment 1: Hadoop installation and verification"
require_cmd java "Install a supported JDK; see docs/UBUNTU_SETUP.md."
hadoop_env
echo
java -version
echo
hadoop version
echo
echo "Hadoop configuration directory: ${HADOOP_CONF_DIR:-${HADOOP_HOME:-"(from PATH)"}/etc/hadoop}"
echo "Checking Java processes:"
if command -v jps >/dev/null 2>&1; then jps; else echo "jps not found; install the JDK (not only a JRE)."; fi
echo
echo "Web interfaces (when daemons are running):"
echo "  NameNode: http://localhost:9870"
echo "  ResourceManager: http://localhost:8088"
echo
echo "To start a configured pseudo-distributed cluster: start-dfs.sh && start-yarn.sh"
echo "To stop it: stop-yarn.sh && stop-dfs.sh"
echo "This script intentionally does not format the NameNode or start/stop system services."
