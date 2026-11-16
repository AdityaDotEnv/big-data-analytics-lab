#!/usr/bin/env bash
set -Eeuo pipefail

MONGO_MAJOR="${MONGO_MAJOR:-8.0}"

if ! command -v apt-get >/dev/null 2>&1 || [[ ! -r /etc/os-release ]]; then
  echo "[ERROR] This installer supports Ubuntu using APT." >&2; exit 1
fi
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *" ubuntu "*|*" linuxmint "*) ;;
  *) echo "[ERROR] Ubuntu or an Ubuntu-based distribution is required (detected ${ID:-unknown})." >&2; exit 1 ;;
esac

# Linux Mint uses its Ubuntu base codename for Ubuntu package repositories.
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
case "$CODENAME" in
  noble|jammy|focal) ;;
  *) echo "[ERROR] MongoDB $MONGO_MAJOR installer supports Ubuntu 20.04/22.04/24.04 here; detected ${CODENAME:-unknown}. See official docs for this release."; exit 1 ;;
esac

if command -v mongosh >/dev/null 2>&1 && command -v mongod >/dev/null 2>&1; then
  echo "MongoDB Server and mongosh already installed."
  mongosh --version
  exit 0
fi

if [[ "$EUID" -eq 0 ]]; then SUDO=; else SUDO=sudo; fi
command -v curl >/dev/null 2>&1 || { $SUDO apt-get update; $SUDO apt-get install -y curl gnupg; }
$SUDO apt-get update
$SUDO apt-get install -y gnupg curl

KEYRING="/usr/share/keyrings/mongodb-server-${MONGO_MAJOR}.gpg"
LIST="/etc/apt/sources.list.d/mongodb-org-${MONGO_MAJOR}.list"
tmp_key="$(mktemp)"
trap 'rm -f "$tmp_key"' EXIT
curl -fsSL "https://pgp.mongodb.com/server-${MONGO_MAJOR}.asc" -o "$tmp_key"
$SUDO gpg --dearmor --yes -o "$KEYRING" "$tmp_key"
echo "deb [ arch=amd64,arm64 signed-by=$KEYRING ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/$MONGO_MAJOR multiverse" | $SUDO tee "$LIST" >/dev/null
$SUDO apt-get update
$SUDO apt-get install -y mongodb-org mongodb-mongosh

if command -v systemctl >/dev/null 2>&1; then
  $SUDO systemctl enable mongod
  $SUDO systemctl start mongod
  $SUDO systemctl --no-pager --full status mongod || true
fi

mongosh "mongodb://127.0.0.1:27017" --quiet --eval 'db.adminCommand({ping:1})'
echo "MongoDB Community $MONGO_MAJOR and mongosh installed and verified."
