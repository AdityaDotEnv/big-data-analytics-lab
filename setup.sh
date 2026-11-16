#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$ROOT/scripts"

usage() {
  cat <<'EOF'
Big Data Analytics Lab installer

Usage:
  ./setup.sh --check
  ./setup.sh --install [all|hadoop|mongodb|java|common]

Install actions use sudo where required and ask before changing the system.
EOF
}

check_one() {
  local label="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  [OK]      %-12s %s\n' "$label" "$(command -v "$cmd")"
  else
    printf '  [MISSING] %s\n' "$label"
  fi
}

install_common() {
  local sudo_cmd=()
  [[ "$EUID" -eq 0 ]] || sudo_cmd=(sudo)
  "${sudo_cmd[@]}" apt-get update
  "${sudo_cmd[@]}" apt-get install -y curl wget ca-certificates gnupg tar maven
}

case "${1:---check}" in
  --help|-h) usage ;;
  --check)
    echo "Big Data Analytics Lab - dependency status"
    check_one Java java
    check_one JDK javac
    check_one Hadoop hadoop
    check_one HDFS hdfs
    check_one Maven mvn
    check_one MongoDB mongod
    check_one mongosh mongosh
    echo
    echo "Install options:"
    echo "  ./setup.sh --install all"
    echo "  ./setup.sh --install hadoop"
    echo "  ./setup.sh --install mongodb"
    echo "  ./setup.sh --install java"
    echo "  ./setup.sh --install common"
    ;;
  --install)
    component="${2:-all}"
    if [[ ! -r /etc/os-release ]]; then
      echo "[ERROR] Cannot identify the operating system." >&2
      exit 1
    fi
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
      *" ubuntu "*|*" linuxmint "*)
        ;;
      *)
        echo "[ERROR] Automatic installation supports Ubuntu and Ubuntu-based distributions." >&2
        exit 1
        ;;
    esac
    case "$component" in
      all)
        install_common
        "$SCRIPTS/install-java.sh"
        "$SCRIPTS/install-hadoop.sh"
        "$SCRIPTS/install-mongodb.sh"
        ;;
      java)
        "$SCRIPTS/install-java.sh"
        ;;
      hadoop)
        "$SCRIPTS/install-java.sh"
        "$SCRIPTS/install-hadoop.sh"
        ;;
      mongodb)
        "$SCRIPTS/install-mongodb.sh"
        ;;
      common)
        install_common
        ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
    echo
    echo "Installation action completed. Run ./setup.sh --check to verify."
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
