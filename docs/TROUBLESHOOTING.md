# Troubleshooting

This document covers common installation, configuration and execution problems encountered while setting up the BCS714D Big Data Analytics Lab on Ubuntu-based Linux systems.

## 1. `hadoop: command not found`

Hadoop may be installed but its binaries may not be in the current shell's `PATH`.

Load the environment:

```bash
source ~/.bashrc
```

Check:

```bash
echo "$HADOOP_HOME"
command -v hadoop
command -v hdfs
```

For the project installation, the expected directory is:

```text
~/.local/opt/hadoop-3.4.3
```

If necessary, configure the current shell:

```bash
export HADOOP_HOME="$HOME/.local/opt/hadoop-3.4.3"
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HOME/.local/bin:$PATH"
```

Then verify:

```bash
hadoop version
hdfs version
```

Do not download another Hadoop copy before checking the existing installation and PATH.

## 2. Installer rejects Linux Mint

Linux Mint identifies itself differently from Ubuntu.

Example:

```text
ID=linuxmint
ID_LIKE="ubuntu debian"
VERSION_CODENAME=zena
UBUNTU_CODENAME=noble
```

A script that checks only for:

```bash
ID=ubuntu
```

will incorrectly reject Linux Mint.

The setup and Java installers should accept Ubuntu-based distributions using `ID_LIKE`, including Linux Mint.

For MongoDB's Ubuntu APT repository, use the Ubuntu base codename:

```bash
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
```

For Mint 22.3, this selects `noble`, not `zena`.

If an installer rejects the distribution, inspect:

```bash
cat /etc/os-release
```

Do not bypass every operating-system check blindly. The repository and package instructions must support the underlying Ubuntu release and architecture.

## 3. Hadoop download is extremely slow

The Hadoop 3.4.3 archive is approximately 491 MiB.

The older Apache archive endpoint may be slow depending on the network route.

The Apache CDN endpoint tested for this project is:

```text
https://dlcdn.apache.org/hadoop/common/hadoop-3.4.3/hadoop-3.4.3.tar.gz
```

Test its availability:

```bash
curl -IL --connect-timeout 10 --max-time 20 \
  https://dlcdn.apache.org/hadoop/common/hadoop-3.4.3/hadoop-3.4.3.tar.gz
```

An HTTP 200 response indicates that the endpoint is reachable.

The installer should use:

```bash
BASE_URL="https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION"
```

Recommended download command:

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

After downloading, check gzip integrity:

```bash
gzip -t "$tmp/$ARCHIVE"
```

This verifies that the archive can be read as a valid gzip stream. It does not independently authenticate the download.

### Important: preserve shell command boundaries

A malformed multiline command can concatenate the final `curl` argument with the next shell command.

Incorrect:

```bash
-o "$tmp/$ARCHIVE"  echo "Extracting..."
```

Correct:

```bash
-o "$tmp/$ARCHIVE"

echo "Extracting..."
```

Keep each command on its own line and validate the script after editing:

```bash
bash -n scripts/install-hadoop.sh
```

### Download completed but extraction did not happen

Inspect:

```bash
ls -lh ~/.local/opt/
find /tmp -maxdepth 2 -name 'hadoop-3.4.3.tar.gz' -ls 2>/dev/null
```

The installer may use a temporary directory that is removed when it exits. A failed run may therefore leave no archive behind.

Inspect the download and extraction section:

```bash
nl -ba scripts/install-hadoop.sh | sed -n '25,65p'
```

Do not assume that a 100% curl progress indicator means Hadoop was extracted successfully. Look for the extraction message and verify the installation directory.

## 4. Hadoop configuration files contain empty defaults

Hadoop ships with non-empty XML templates. A setup script that checks only:

```bash
[[ ! -s "$HADOOP_HOME/etc/hadoop/core-site.xml" ]]
```

will not replace the default template because the file already contains XML content.

Inspect:

```bash
cat "$HADOOP_HOME/etc/hadoop/core-site.xml"
cat "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
```

For this project's single-node setup, `core-site.xml` must define:

```xml
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
</property>
```

And `hdfs-site.xml` must define:

```xml
<property>
    <name>dfs.replication</name>
    <value>1</value>
</property>
```

It must also define the local NameNode and DataNode storage directories.

See the complete replacement files and commands in:

```text
docs/UBUNTU_SETUP.md
```

Back up existing XML files before replacing them.

Verify the effective configuration:

```bash
hdfs getconf -confKey fs.defaultFS
hdfs getconf -confKey dfs.replication
hdfs getconf -confKey dfs.namenode.name.dir
hdfs getconf -confKey dfs.datanode.data.dir
```

Do not format the NameNode to fix a configuration problem.

## 5. HDFS connection refused

HDFS may not be running, or the configured NameNode address may differ from the client configuration.

Check:

```bash
hdfs getconf -confKey fs.defaultFS
jps
```

Start HDFS if this is your own local cluster and you are authorized to manage it:

```bash
start-dfs.sh
```

Check:

```bash
hdfs dfsadmin -report
```

For a single-node cluster, look for one live DataNode.

Do not format the NameNode as a generic connection-refused fix.

## 6. NameNode formatting

Formatting is a destructive operation that resets NameNode metadata.

Only use:

```bash
hdfs namenode -format
```

for a new, dedicated local lab instance, before it has been initialized with data.

Do not repeatedly format an existing installation.

Do not format a college or shared Hadoop cluster.

If HDFS has already been initialized, investigate the logs and configuration instead.

## 7. Hadoop daemon scripts report SSH permission denied

A typical error is:

```text
Permission denied (publickey,password).
```

Hadoop daemon scripts may connect using either `localhost` or the machine hostname.

First test:

```bash
ssh localhost
```

If that succeeds, but the SecondaryNameNode still fails, check:

```bash
hostname
cat ~/.ssh/config
```

The SSH configuration may contain an entry for `localhost` but no entry for the machine hostname.

If the dedicated key exists:

```bash
ls -l ~/.ssh/id_ed25519_hadoop_lab*
```

Add a hostname alias:

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

If authentication still fails, inspect:

```bash
cat ~/.ssh/authorized_keys
ls -l ~/.ssh/
```

If the dedicated public key is missing from `authorized_keys`, append it:

```bash
cat ~/.ssh/id_ed25519_hadoop_lab.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Do not overwrite existing SSH keys or remove unrelated authorized keys.

### Restart HDFS after correcting SSH

Stop the partially started local daemons:

```bash
stop-dfs.sh
```

Then start them again:

```bash
start-dfs.sh
jps
```

Expected important processes:

```text
NameNode
DataNode
SecondaryNameNode
Jps
```

Check:

```bash
hdfs dfsadmin -report
```

Do not format the NameNode again.

## 8. `jps` does not show all Hadoop daemons

Check the SSH configuration and Hadoop logs.

```bash
jps
```

For HDFS:

- NameNode
- DataNode
- SecondaryNameNode

For YARN, when started:

- ResourceManager
- NodeManager

Inspect logs:

```bash
ls -lt "$HADOOP_HOME/logs" | head
```

Read the relevant log:

```bash
tail -n 80 "$HADOOP_HOME"/logs/*namenode*.log
tail -n 80 "$HADOOP_HOME"/logs/*datanode*.log
tail -n 80 "$HADOOP_HOME"/logs/*secondarynamenode*.log
```

Only restart services that belong to your local lab installation.

## 9. Hadoop environment is missing after SSH login

An SSH session may open in the user's home directory rather than the project directory.

For example:

```text
aditya@machine:~$
```

The project launcher will not be available there unless you change directories.

Return to the project:

```bash
cd ~/Downloads/big-data-analytics-lab
```

Load the environment if necessary:

```bash
source ~/.bashrc
```

Check:

```bash
echo "$HADOOP_HOME"
command -v hadoop
```

## 10. MapReduce reports incompatible Hadoop classes

The Maven Hadoop dependency version should match the Hadoop installation used to execute the job.

Inspect:

```bash
grep -n 'hadoop.version' \
  experiments/03-mapreduce-wordcount/pom.xml
```

For the local Hadoop 3.4.3 installation, the project should use Hadoop 3.4.3 client dependencies.

After changing the dependency version, rebuild the project:

```bash
cd experiments/03-mapreduce-wordcount
mvn clean package
```

Return to the repository root afterward:

```bash
cd ~/Downloads/big-data-analytics-lab
```

## 11. Maven cannot download dependencies

Check:

- Internet connectivity.
- Proxy configuration.
- Maven Central availability.
- Local Maven cache.

Run:

```bash
mvn -version
```

Try a build:

```bash
cd experiments/03-mapreduce-wordcount
mvn -U clean package
```

A first build requires network access unless dependencies are already cached.

## 12. `mongosh` cannot connect

Check the connection URI:

```bash
echo "$MONGODB_URI"
```

Check the service:

```bash
sudo systemctl status mongod --no-pager
```

Ping the local server:

```bash
mongosh "mongodb://127.0.0.1:27017" \
  --quiet \
  --eval 'db.adminCommand({ping:1})'
```

If MongoDB is installed but stopped, and you are authorized to manage the local service:

```bash
sudo systemctl start mongod
```

If the lab uses a remote server, set the URI provided by the administrator:

```bash
export MONGODB_URI="mongodb://HOST:PORT"
```

The experiment must use the intended MongoDB server. Do not assume that a local service is the correct database for a shared lab.

## 13. MongoDB authentication failure

Set `MONGODB_URI` to the connection URI provided by the lab administrator.

Do not commit credentials to Git.

Avoid putting passwords directly into commands that will remain in shell history.

## 14. MongoDB repository unsupported

The MongoDB installer uses MongoDB Community 8.0 and an Ubuntu release-specific APT repository.

On Linux Mint, use the Ubuntu base codename rather than the Mint codename.

For example:

```text
Linux Mint codename: zena
Ubuntu base codename: noble
```

If the repository does not support the detected Ubuntu release or architecture, stop and follow the official MongoDB installation guide for that release.

Official guide:

https://www.mongodb.com/docs/manual/administration/install-on-linux/

Do not add an arbitrary repository or import keys from an outdated tutorial.

## 15. Duplicate APT repository warnings

APT may report that the same repository is configured more than once.

For example, the same `osquery` repository may appear in:

```text
/etc/apt/sources.list.d/additional-repositories.list
/etc/apt/sources.list.d/osquery.list
```

These warnings do not necessarily mean package installation failed.

Inspect both files:

```bash
sudo cat /etc/apt/sources.list.d/additional-repositories.list
sudo cat /etc/apt/sources.list.d/osquery.list
```

Resolve duplicates deliberately. Do not delete repository files without checking their contents.

## 16. APT suggests autoremove

APT may list packages as automatically installed and no longer required.

Do not run:

```bash
sudo apt autoremove
```

without reviewing the proposed package list.

This is particularly important on development machines using:

- NVIDIA drivers
- Custom kernels
- Manually installed GPU libraries
- Development toolchains

Review the package list and confirm that no required driver or kernel components will be removed.

## 17. Permission denied on `run.sh`

Make the project scripts executable:

```bash
chmod +x run.sh setup.sh install.sh
chmod +x scripts/*.sh
chmod +x experiments/*/run.sh
```

Then:

```bash
./run.sh
```

Do not run the experiment scripts with `sudo` unless the script explicitly documents a privileged operation.

## 18. Verify the complete dependency setup

From the repository root:

```bash
./setup.sh --check
```

Expected dependencies:

- Java
- JDK
- Hadoop
- HDFS
- Maven
- MongoDB
- mongosh

This check verifies command availability. It does not prove that every experiment has passed.

For service health, also run:

```bash
jps
hdfs dfsadmin -report
mongosh --quiet --eval 'db.adminCommand({ping:1})'
```

Run each experiment individually and retain its actual output as evidence of successful execution.