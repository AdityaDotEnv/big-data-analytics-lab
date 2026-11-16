#!/usr/bin/env bash
set -Eeuo pipefail
if command -v javac >/dev/null 2>&1; then
  echo "JDK already available: $(javac -version 2>&1)"; exit 0
fi
if [[ ! -r /etc/os-release ]]; then
  echo "[ERROR] Cannot identify the operating system." >&2; exit 1
fi
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *" ubuntu "*|*" linuxmint "*) ;;
  *) echo "[ERROR] Automatic JDK installation supports Ubuntu and Ubuntu-based distributions." >&2; exit 1 ;;
esac
if [[ "$EUID" -eq 0 ]]; then SUDO=; else SUDO=sudo; fi
$SUDO apt-get update
# Java 17 is available on current Ubuntu LTS releases and is suitable for current Hadoop 3.x setups.
$SUDO apt-get install -y openjdk-17-jdk
java -version
javac -version
