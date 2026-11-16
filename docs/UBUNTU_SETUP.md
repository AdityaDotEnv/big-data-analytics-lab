# Ubuntu and Linux Mint Setup

This guide describes native installation and configuration of the BCS714D Big Data Analytics Lab.

It covers Ubuntu and Ubuntu-based distributions such as Linux Mint. The installation uses APT, Apache Hadoop binaries, Java, Maven and MongoDB Community Server.

Docker is not required.

## 1. Inspect the system

From the repository root:

```bash
cat /etc/os-release
./setup.sh --check
```

For Linux Mint, the operating system information normally includes:

```text
ID=linuxmint
ID_LIKE="ubuntu debian"
UBUNTU_CODENAME=noble
```

The Ubuntu base codename matters when configuring Ubuntu package repositories from Linux Mint.

The project setup scripts should accept Ubuntu-based distributions and use the Ubuntu base codename for repositories that require it.

## 2. Common utilities

Install common utilities explicitly:

```bash
./setup.sh --install common
```

The common installation includes utilities such as:

- curl
- wget
- tar
- gnupg
- Maven
- CA certificates

Review the APT package list before approving installation.

Check:

```bash
command -v curl
command -v wget
command -v tar
command -v mvn
```

### Java

Check whether a JDK already exists:

```bash
java -version
javac -version
```

If a JDK is missing:

```bash
./setup.sh --install java
```

The Java installer uses the distribution's APT packages. The exact Java version may depend on the installer and the distribution.

The Hadoop 3.4.3 installation tested for this project used OpenJDK 21. Existing Java installations are reused when a working JDK is detected.

Do not install another JDK unnecessarily if the existing JDK works with the Hadoop version being used.

## 3. Hadoop installation

The project installs Apache Hadoop 3.4.3 locally when no usable Hadoop installation is detected.

```bash
./setup.sh --install hadoop
```

The installer:

1. Reuses an existing Hadoop command if one is already available.
2. Checks for a JDK.
3. Downloads Apache Hadoop 3.4.3 if a local copy is missing.
4. Extracts Hadoop under:

   ```text
   ~/.local/opt/hadoop-3.4.3
   ```

5. Creates command symlinks under:

   ```text
   ~/.local/bin
   ```

6. Adds Hadoop environment exports to `~/.bashrc` and `~/.profile`.
7. Sets `JAVA_HOME` in Hadoop's `hadoop-env.sh`.
8. May offer to create a dedicated SSH key for local Hadoop daemon management.

The installer does **not** automatically format the NameNode or start HDFS daemons.

### 3.1 Download source and slow connections

The recommended Hadoop 3.4.3 archive URL is:

```text
https://dlcdn.apache.org/hadoop/common/hadoop-3.4.3/hadoop-3.4.3.tar.gz
```

The archive is approximately 491 MiB.

The Apache CDN was reachable during testing. The older `archive.apache.org` endpoint was extremely slow on the tested connection.

If changing the download source in `scripts/install-hadoop.sh`, use:

```bash
BASE_URL="https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION"
```

Keep the download command as a properly separated multiline shell command:

```bash
curl -fL \
  --connect-timeout 20 \
  --max-time 3600 \
  --retry 5 \
  --retry-delay 5 \
  --retry-all-errors \
  --progress-bar \
  "$BASE_URL/$ARCHIVE" \
  -o "$tmp/$ARCHIVE"
```

Do not append another shell command to the final `-o` line. Each command must be separated by a newline or `;`.

The installer should check the downloaded archive before extraction:

```bash
gzip -t "$tmp/$ARCHIVE"
```

This checks gzip integrity. It is not a cryptographic authenticity check.

### 3.2 Load the environment

After installation, open a new terminal or run:

```bash
source ~/.bashrc
```

Check:

```bash
echo "$JAVA_HOME"
echo "$HADOOP_HOME"

java -version
javac -version
hadoop version
hdfs version
```

Expected local Hadoop location:

```text
/home/USER/.local/opt/hadoop-3.4.3
```

If commands are not found, inspect:

```bash
grep -n 'HADOOP_HOME\|PATH=' ~/.bashrc
ls -l ~/.local/bin/hadoop ~/.local/bin/hdfs
```

Do not install a second Hadoop copy until the existing PATH and installation have been checked.

## 4. Configure single-node HDFS

**Important:** Hadoop ships with non-empty default XML template files. A script that only checks whether `core-site.xml` or `hdfs-site.xml` is empty will not replace those templates.

Inspect the files:

```bash
cat "$HADOOP_HOME/etc/hadoop/core-site.xml"
cat "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
```

For this project's single-node lab configuration, replace their contents with the following.

### 4.1 Configure `core-site.xml`

```bash
cp "$HADOOP_HOME/etc/hadoop/core-site.xml" \
   "$HADOOP_HOME/etc/hadoop/core-site.xml.bak"

cat > "$HADOOP_HOME/etc/hadoop/core-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF
```

### 4.2 Configure `hdfs-site.xml`

```bash
cp "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" \
   "$HADOOP_HOME/etc/hadoop/hdfs-site.xml.bak"

cat > "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${HOME}/.local/share/hadoop/dfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${HOME}/.local/share/hadoop/dfs/data</value>
    </property>
</configuration>
EOF
```

These paths use the current user's home directory.

### 4.3 Verify the configuration

Run:

```bash
hdfs getconf -confKey fs.defaultFS
hdfs getconf -confKey dfs.replication
hdfs getconf -confKey dfs.namenode.name.dir
hdfs getconf -confKey dfs.datanode.data.dir
```

Expected values:

```text
hdfs://localhost:9000
1
file:///home/USER/.local/share/hadoop/dfs/name
file:///home/USER/.local/share/hadoop/dfs/data
```

The exact file URI may vary slightly depending on Hadoop's normalization.

Do not format the NameNode until the configuration is correct.

## 5. Configure passwordless SSH for Hadoop

Hadoop daemon scripts may use SSH to start processes on the local machine.

The installer may offer to:

- Generate a dedicated SSH key.
- Add its public key to `~/.ssh/authorized_keys`.
- Install OpenSSH server if it is missing.
- Enable or start the SSH service.

These actions require user approval.

Test localhost SSH:

```bash
ssh localhost
```

If the installer generated the dedicated key but authentication fails, inspect:

```bash
ls -l ~/.ssh/id_ed25519_hadoop_lab*
cat ~/.ssh/config
```

The private key should be readable only by its owner:

```bash
chmod 600 ~/.ssh/id_ed25519_hadoop_lab
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config
```

### 5.1 Configure the machine hostname alias

On some machines, Hadoop's SecondaryNameNode uses the system hostname rather than `localhost`.

Find the hostname:

```bash
hostname
```

For example:

```text
aditya-IdeaPad-L340-15IRH-Gaming
```

If `ssh localhost` works but Hadoop still reports `Permission denied` for the hostname, add an SSH host alias.

Replace the example hostname and username automatically using:

```bash
HOST_NAME="$(hostname)"

if ! grep -qE "^Host[[:space:]].*${HOST_NAME}([[:space:]]|$)" ~/.ssh/config 2>/dev/null; then
  cat >> ~/.ssh/config <<EOF

Host ${HOST_NAME}
    HostName localhost
    User ${USER}
    IdentityFile ~/.ssh/id_ed25519_hadoop_lab
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF
fi

chmod 600 ~/.ssh/config
```

Test:

```bash
ssh "$(hostname)"
```

A successful login should not require a password.

Exit the SSH session:

```bash
exit
```

Do not overwrite existing SSH keys or unrelated SSH configuration.

## 6. Initialize and start HDFS

**Warning: NameNode formatting is destructive.**

Only format a brand-new, dedicated local lab NameNode. Formatting resets HDFS metadata. Never format a shared college cluster or an existing HDFS installation containing data.

After verifying the configuration and confirming that this is a fresh local installation, format once:

```bash
hdfs namenode -format
```

Start HDFS:

```bash
start-dfs.sh
```

Check Java processes:

```bash
jps
```

Expected important processes:

```text
NameNode
DataNode
SecondaryNameNode
Jps
```

Check cluster health:

```bash
hdfs dfsadmin -report
```

For a healthy single-node setup, look for:

- Live datanodes: 1
- Missing blocks: 0
- Corrupt replicas: 0
- Under-replicated blocks: 0

### Start YARN when needed

MapReduce jobs that use YARN require YARN services:

```bash
start-yarn.sh
jps
```

Expected additional processes may include:

```text
ResourceManager
NodeManager
```

Do not start YARN unless the experiment requires it.

### Stop services

Stop only services that you started:

```bash
stop-yarn.sh
stop-dfs.sh
```

Do not stop services on a shared or centrally managed cluster.

Official documentation:

https://hadoop.apache.org/docs/

## 7. MongoDB Community Server and mongosh

The project installer uses MongoDB's official APT repository to install MongoDB Community Server 8.0 and `mongosh`.

```bash
./setup.sh --install mongodb
```

The installer enables and starts the `mongod` service.

### Ubuntu-based distributions and Linux Mint

Linux Mint has its own distribution codename. For example:

```text
VERSION_CODENAME=zena
UBUNTU_CODENAME=noble
```

MongoDB's Ubuntu repository must use the Ubuntu base codename (`noble`) rather than the Mint codename (`zena`).

The installer should select:

```bash
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
```

The repository should be checked for support for the selected Ubuntu release and CPU architecture before installation.

### Verify MongoDB

Check the service:

```bash
sudo systemctl status mongod --no-pager
```

Check the shell:

```bash
mongosh --version
```

Ping the local server:

```bash
mongosh "mongodb://127.0.0.1:27017" \
  --quiet \
  --eval 'db.adminCommand({ping:1})'
```

A successful connection returns:

```javascript
{ ok: 1 }
```

If MongoDB is installed but stopped, and you are authorized to manage the local service:

```bash
sudo systemctl start mongod
```

The MongoDB experiments can use a remote connection if the lab administrator provides one:

```bash
export MONGODB_URI="mongodb://HOST:PORT"
```

Do not put passwords or credentials in source control.

Official installation guide:

https://www.mongodb.com/docs/manual/administration/install-on-linux/

MongoDB Shell installation:

https://www.mongodb.com/docs/mongodb-shell/install/

## 8. Run the lab

Return to the project directory:

```bash
cd ~/Downloads/big-data-analytics-lab
```

Check dependencies:

```bash
./setup.sh --check
```

Launch the interactive menu:

```bash
./run.sh
```

Or launch an experiment directly:

```bash
./run.sh 1
./run.sh 2
./run.sh 3
./run.sh 4
./run.sh 5
./run.sh 6
```

Run HDFS experiments only after HDFS is started and healthy.

Run MongoDB experiments only after the MongoDB server is reachable.

## 9. APT warnings and package cleanup

APT may report duplicate repository entries. For example, the same repository may be configured in two files under `/etc/apt/sources.list.d/`.

These warnings are not necessarily installation failures. Inspect the duplicate entries and resolve them deliberately rather than deleting repository files blindly.

APT may also suggest running:

```bash
sudo apt autoremove
```

Do not approve this blindly on a development machine. Review the proposed package list first, especially if the system uses NVIDIA drivers, custom kernels or manually installed packages.

## 10. Complete installation command

For a new supported Ubuntu-based machine, the full dependency installation can be requested with:

```bash
./setup.sh --install all
```

This can install or configure multiple system components and may require several sudo approvals.

For troubleshooting and safer staged installation, prefer:

```bash
./setup.sh --install common
./setup.sh --install java
./setup.sh --install hadoop
./setup.sh --install mongodb
```

The staged approach makes it easier to identify which component failed.