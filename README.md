# Big Data Analytics Lab — BCS714D

Native Linux implementations of the six experiments listed in the VTU BCS714D Big Data Analytics Lab manual.

The project is designed for Ubuntu and Ubuntu-based distributions, including Linux Mint. It uses native installations of Hadoop, Java, Maven and MongoDB. Docker is not required.

## Quick start

```bash
git clone https://github.com/AdityaDotEnv/big-data-analytics-lab.git
cd big-data-analytics-lab

chmod +x run.sh setup.sh install.sh scripts/*.sh experiments/*/run.sh

# Inspect installed dependencies
./setup.sh --check

# Launch the interactive experiment menu
./run.sh
```

Replace `USERNAME` with the actual GitHub account or organization hosting the repository.

Run an experiment directly:

```bash
./run.sh 1
./run.sh 2
./run.sh 3
./run.sh 4
./run.sh 5
./run.sh 6
```

Alternatively, run an individual experiment:

```bash
./experiments/01-hadoop-installation/run.sh
./experiments/02-hdfs-file-management/run.sh
./experiments/03-mapreduce-wordcount/run.sh
./experiments/04-mongodb-crud/run.sh
./experiments/05-mongodb-queries-arrays/run.sh
./experiments/06-mongodb-aggregation/run.sh
```

## Experiments

| No. | Experiment | Main technologies |
|---|---|---|
| 1 | Hadoop installation, configuration and service verification | Java, Hadoop, HDFS |
| 2 | HDFS directory and file management | HDFS CLI |
| 3 | MapReduce Word Count | Java, Hadoop, Maven |
| 4 | MongoDB database basics and CRUD operations | MongoDB, mongosh |
| 5 | MongoDB NULL handling, count, limit, sort, skip and arrays | MongoDB, mongosh |
| 6 | MongoDB aggregation pipeline | MongoDB, mongosh |

The supplied manual's program list contains these six experiments. Although the course outcomes mention Pig, Hive and Spark, they are not included as additional experiments in this repository.

## Project design

- Native Linux tools; no Docker or Eclipse requirement.
- Each experiment has an independent `run.sh`.
- `run.sh` provides a master interactive launcher.
- `setup.sh --check` checks the availability of required dependencies.
- `setup.sh --install` supports explicit dependency installation.
- Existing installations are reused where detected.
- Hadoop is installed locally under `~/.local/opt` when a local installation is needed.
- MongoDB Community Server is installed through its official APT repository.
- MongoDB experiments use dedicated lab databases.
- Destructive operations require deliberate user action wherever applicable.

## Requirements

Recommended environment:

- Ubuntu 22.04 or 24.04, or an Ubuntu-based distribution such as Linux Mint.
- Bash and standard Linux utilities.
- Java JDK compatible with the installed Hadoop release.
- Apache Hadoop and HDFS commands for Experiments 1–3.
- Maven for building the MapReduce project.
- MongoDB Community Server and `mongosh` for Experiments 4–6.
- OpenSSH server and passwordless local SSH for Hadoop daemon scripts where required.

The tested installation path described in the documentation includes:

| Component | Tested environment |
|---|---|
| Operating system | Linux Mint 22.3 (Zena), Ubuntu 24.04 Noble base |
| Java | OpenJDK 21 |
| Hadoop | Apache Hadoop 3.4.3 |
| Maven | 3.8.7 |
| MongoDB | Community Server 8.0 |
| MongoDB Shell | mongosh |

This records the installation environment, not a claim that every experiment has already passed on every supported distribution.

## Installation

Inspect the current system:

```bash
./setup.sh --check
```

Install common utilities:

```bash
./setup.sh --install common
```

Install Hadoop and its Java prerequisite:

```bash
./setup.sh --install hadoop
```

Install MongoDB:

```bash
./setup.sh --install mongodb
```

Install all supported components:

```bash
./setup.sh --install all
```

Installation modifies the operating system and may use `sudo`. Review package changes and prompts before approving them, especially on college or shared machines.

See:

- [Ubuntu and Linux Mint setup](docs/UBUNTU_SETUP.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Hadoop first-time setup

The Hadoop installer downloads and extracts the distribution, but Hadoop's shipped XML files may already contain non-empty default templates. Those templates must be replaced with the lab's single-node configuration before starting HDFS.

After configuring Hadoop, verify:

```bash
hdfs getconf -confKey fs.defaultFS
hdfs getconf -confKey dfs.replication
```

For a fresh, dedicated local lab instance only, initialize the NameNode once:

```bash
hdfs namenode -format
```

Then start HDFS:

```bash
start-dfs.sh
jps
hdfs dfsadmin -report
```

Expected HDFS processes:

- NameNode
- DataNode
- SecondaryNameNode

Do not format an existing NameNode or a shared college cluster. Formatting resets NameNode metadata.

See [Ubuntu setup](docs/UBUNTU_SETUP.md) for the full procedure.

## Configuration

Optional environment variables:

| Variable | Purpose | Default |
|---|---|---|
| `HADOOP_HOME` | Hadoop installation directory | Detected/local installation |
| `JAVA_HOME` | Java installation directory | Detected Java |
| `MONGODB_URI` | MongoDB connection URI | `mongodb://127.0.0.1:27017` |
| `LAB_DB_PREFIX` | Prefix for experiment databases | `bcs714d_lab` |

For example:

```bash
export MONGODB_URI="mongodb://127.0.0.1:27017"
export LAB_DB_PREFIX="bcs714d_lab"
```

## Safety

- Hadoop NameNode formatting is never performed automatically.
- Do not format an existing or shared HDFS installation.
- Do not start or stop a centrally managed Hadoop cluster without authorization.
- MongoDB experiments should operate only on their dedicated lab databases.
- Do not put database credentials or private connection strings in source control.
- Do not run `sudo apt autoremove` blindly on a development machine. Review the packages first, especially if NVIDIA drivers or custom kernels are installed.
- Review all installation prompts before changing a college lab PC.

## Current validation status

The following infrastructure checks have been completed on the development machine:

- Java JDK and Maven detected.
- Hadoop 3.4.3 installed and detected.
- MongoDB Community 8.0 installed and detected.
- `mongosh` successfully connected to the local MongoDB server.
- Passwordless SSH to `localhost` and the machine hostname configured.
- NameNode, DataNode and SecondaryNameNode started successfully.
- HDFS reported one live DataNode, zero missing blocks and zero corrupt replicas.

The remaining experiments must be run and validated individually. Infrastructure installation does not imply that all six experiment workflows have already been tested.

## License

MIT. See [LICENSE](LICENSE).