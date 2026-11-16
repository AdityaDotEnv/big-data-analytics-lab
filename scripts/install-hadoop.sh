#!/usr/bin/env bash
set -Eeuo pipefail

HADOOP_VERSION="${HADOOP_VERSION:-3.4.3}"
INSTALL_ROOT="${HADOOP_INSTALL_ROOT:-$HOME/.local/opt}"
HADOOP_HOME="$INSTALL_ROOT/hadoop-$HADOOP_VERSION"
ARCHIVE="hadoop-$HADOOP_VERSION.tar.gz"
BASE_URL="https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION"

if [[ "$(uname -s)" != Linux ]]; then echo "[ERROR] This installer targets Linux." >&2; exit 1; fi
if ! command -v apt-get >/dev/null 2>&1; then echo "[ERROR] APT-based Ubuntu/Debian system required." >&2; exit 1; fi

if command -v hadoop >/dev/null 2>&1 && [[ "${FORCE_LOCAL_HADOOP_INSTALL:-0}" != 1 ]]; then
  echo "Hadoop already detected: $(hadoop version 2>/dev/null | head -n1)"
  echo "Reusing the existing installation. Set FORCE_LOCAL_HADOOP_INSTALL=1 to add a separate local copy."
  exit 0
fi

if [[ ! -d "$HADOOP_HOME" ]]; then
  missing=()
  for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    if [[ "$EUID" -eq 0 ]]; then SUDO=; else SUDO=sudo; fi
    "$SUDO" apt-get update
    "$SUDO" apt-get install -y curl tar
  fi
  mkdir -p "$INSTALL_ROOT"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  echo "Downloading Apache Hadoop $HADOOP_VERSION..."
  curl -fL \
    --connect-timeout 20 \
    --max-time 3600 \
    --retry 5 \
    --retry-delay 5 \
    --retry-all-errors \
    --progress-bar \
    "$BASE_URL/$ARCHIVE" \
    -o "$tmp/$ARCHIVE"

  echo "Download completed. Checking archive..."
  gzip -t "$tmp/$ARCHIVE"

  echo "Extracting into $INSTALL_ROOT..."
  tar -xzf "$tmp/$ARCHIVE" -C "$INSTALL_ROOT"

fi

# Hadoop 3.4.x is run with a supported JDK; use the JDK already present when possible.
JAVA_BIN="$(command -v java || true)"
if [[ -z "$JAVA_BIN" ]]; then
  echo "Java is required. Run ./setup.sh --install java, then rerun this installer."
  exit 1
fi
JAVA_REAL="$(readlink -f "$JAVA_BIN")"
JAVA_HOME_DETECTED="$(dirname "$(dirname "$JAVA_REAL")")"
if [[ ! -x "$JAVA_HOME_DETECTED/bin/javac" ]]; then
  echo "A JDK (not only a JRE) is required. Install one with ./setup.sh --install java."
  exit 1
fi

mkdir -p "$HADOOP_HOME/logs" "$HOME/.local/bin"
if ! grep -q '^export JAVA_HOME=' "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"; then
  printf '\nexport JAVA_HOME="%s"\n' "$JAVA_HOME_DETECTED" >> "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
else
  sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=\"$JAVA_HOME_DETECTED\"|" "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
fi

# Create a basic single-node configuration only when no config exists.
# Never overwrite an existing lab/cluster configuration.
if [[ ! -s "$HADOOP_HOME/etc/hadoop/core-site.xml" ]]; then
  cat > "$HADOOP_HOME/etc/hadoop/core-site.xml" <<'XML'
<?xml version="1.0"?>
<configuration>
  <property><name>fs.defaultFS</name><value>hdfs://localhost:9000</value></property>
</configuration>
XML
fi
if [[ ! -s "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" ]]; then
  cat > "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" <<'XML'
<?xml version="1.0"?>
<configuration>
  <property><name>dfs.replication</name><value>1</value></property>
  <property><name>dfs.namenode.name.dir</name><value>file://${user.home}/.local/share/hadoop/dfs/name</value></property>
  <property><name>dfs.datanode.data.dir</name><value>file://${user.home}/.local/share/hadoop/dfs/data</value></property>
</configuration>
XML
fi

for bin in hadoop hdfs yarn mapred; do ln -sfn "$HADOOP_HOME/bin/$bin" "$HOME/.local/bin/$bin"; done
for bin in start-dfs.sh stop-dfs.sh start-yarn.sh stop-yarn.sh; do ln -sfn "$HADOOP_HOME/sbin/$bin" "$HOME/.local/bin/$bin"; done

PROFILE_LINE='export HADOOP_HOME="$HOME/.local/opt/hadoop-'"$HADOOP_VERSION"'"'
PATH_LINE='export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HOME/.local/bin:$PATH"'
for profile in "$HOME/.bashrc" "$HOME/.profile"; do
  touch "$profile"
  grep -Fq "$PROFILE_LINE" "$profile" || printf '\n# Big Data Analytics Lab Hadoop\n%s\n%s\n' "$PROFILE_LINE" "$PATH_LINE" >> "$profile"
done
export HADOOP_HOME PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HOME/.local/bin:$PATH"

cat <<EOF2

Hadoop $HADOOP_VERSION installed at: $HADOOP_HOME
JAVA_HOME: $JAVA_HOME_DETECTED
Environment variables added to ~/.bashrc and ~/.profile.

This installer configured a single-node HDFS setup. It has NOT formatted the NameNode
or started Hadoop services. Open a new terminal (or source ~/.bashrc), then review:
  $HADOOP_HOME/etc/hadoop/core-site.xml
  $HADOOP_HOME/etc/hadoop/hdfs-site.xml

To enable daemon startup scripts, passwordless SSH to localhost is required.
EOF2

if command -v ssh >/dev/null 2>&1 && command -v ssh-keygen >/dev/null 2>&1; then
  if [[ ! -f "$HOME/.ssh/id_ed25519_hadoop_lab" ]]; then
    read -r -p "Generate a dedicated SSH key for localhost Hadoop daemon control? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
      ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/id_ed25519_hadoop_lab"
      cat "$HOME/.ssh/id_ed25519_hadoop_lab.pub" >> "$HOME/.ssh/authorized_keys"
      chmod 600 "$HOME/.ssh/authorized_keys"
      touch "$HOME/.ssh/config"
      if ! grep -q 'Host localhost # bcs714d-hadoop' "$HOME/.ssh/config"; then
        cat >> "$HOME/.ssh/config" <<'SSHCFG'

Host localhost # bcs714d-hadoop
  IdentityFile ~/.ssh/id_ed25519_hadoop_lab
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
SSHCFG
      fi
      chmod 600 "$HOME/.ssh/config"
      if ! command -v sshd >/dev/null 2>&1; then
        read -r -p "Install OpenSSH server for local Hadoop daemon scripts? [y/N] " ssh_ans
        if [[ "$ssh_ans" =~ ^[Yy]$ ]]; then
          if [[ "$EUID" -eq 0 ]]; then SUDO=; else SUDO=sudo; fi
          $SUDO apt-get update
          $SUDO apt-get install -y openssh-server
          $SUDO systemctl enable --now ssh
        fi
      elif command -v systemctl >/dev/null 2>&1; then
        if ! systemctl is-active --quiet ssh; then
          read -r -p "Start the local SSH service for Hadoop? [y/N] " ssh_ans
          if [[ "$ssh_ans" =~ ^[Yy]$ ]]; then
            if [[ "$EUID" -eq 0 ]]; then SUDO=; else SUDO=sudo; fi
            $SUDO systemctl enable --now ssh
          fi
        fi
      fi
      echo "SSH key prepared. Test with: ssh localhost"
    fi
  else
    echo "Existing SSH key detected; left it untouched. Configure localhost SSH manually if needed."
  fi
else
  echo "SSH tools not detected. Install with: sudo apt install openssh-client openssh-server"
fi

echo "First-time NameNode initialization is a separate, destructive action. Only if this is a NEW local lab instance:"
echo "  hdfs namenode -format"
echo "Then start: start-dfs.sh && start-yarn.sh"
echo "Stop: stop-yarn.sh && stop-dfs.sh"
