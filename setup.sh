#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$ROOT/scripts"
usage(){ cat <<'TXT'
BIS701 setup
Usage: ./setup.sh --check
       ./setup.sh --install [all|common|java|hadoop|mongodb|pig|spark|hive|analytics]

'all' installs common tools, Java, Hadoop, MongoDB, Pig, Spark and Hive.
Hive is available separately: ./setup.sh --install hive
TXT
}
check(){ local label="$1" cmd="$2"; if command -v "$cmd" >/dev/null 2>&1; then printf '  [OK] %-12s %s\n' "$label" "$(command -v "$cmd")"; else printf '  [MISSING] %s (%s)\n' "$label" "$cmd"; fi; }
install_common(){ local s=(); [[ $EUID -eq 0 ]] || s=(sudo); "${s[@]}" apt-get update; "${s[@]}" apt-get install -y curl wget ca-certificates tar gzip maven; }
case "${1:---check}" in
 --help|-h) usage;;
 --check)
  echo 'BIS701 dependency status'; check Java java; check JDK javac; check Maven mvn; check Hadoop hadoop; check HDFS hdfs; check MongoDB mongod; check mongosh mongosh; check Pig pig; check Spark spark-submit; check Beeline beeline
  echo; echo 'Install commands: ./setup.sh --install all | java | hadoop | mongodb | pig | spark | hive | analytics';;
 --install)
  component="${2:-all}"
  [[ -r /etc/os-release ]] || { echo 'Cannot identify OS.' >&2; exit 1; }; . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in *ubuntu*|*linuxmint*) ;; *) echo 'Automatic installation supports Ubuntu-based distributions.' >&2; exit 1;; esac
  case "$component" in
   common) install_common;;
   java) "$SCRIPTS/install-java.sh";;
   hadoop) "$SCRIPTS/install-java.sh"; "$SCRIPTS/install-hadoop.sh";;
   mongodb) "$SCRIPTS/install-mongodb.sh";;
   pig) install_common; "$SCRIPTS/install-pig.sh";;
   spark) install_common; "$SCRIPTS/install-spark.sh";;
   hive) install_common; "$SCRIPTS/install-hive.sh";;
   analytics) install_common; "$SCRIPTS/install-pig.sh"; "$SCRIPTS/install-spark.sh"; "$SCRIPTS/install-hive.sh";;
   all) install_common; "$SCRIPTS/install-java.sh"; "$SCRIPTS/install-hadoop.sh"; "$SCRIPTS/install-mongodb.sh"; "$SCRIPTS/install-pig.sh"; "$SCRIPTS/install-spark.sh"; "$SCRIPTS/install-hive.sh";;
   *) usage >&2; exit 2;;
  esac
  echo; echo 'Run ./setup.sh --check to verify. Open a new terminal (or source ~/.bashrc) after installing Apache tools.';;
 *) usage >&2; exit 2;;
esac
