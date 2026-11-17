# BIS701 — Big Data Analytics Lab

A Java-first implementation of the eight BIS701 practical experiments. The experiment logic is Java. Pig Latin and HiveQL statements are submitted through their Java APIs/JDBC because those practicals must execute on the actual Pig and Hive runtimes.

## Requirements

- Linux Mint / Ubuntu
- JDK 11 or newer (JDK 17 recommended for current Hive 4 installations)
- Maven 3.8+
- Hadoop 3.x with HDFS configured for single-node use
- MongoDB for Experiment 5
- Apache Pig for Experiment 6
- Apache HiveServer2 for Experiment 7
- Apache Spark for Experiment 8 Spark mode

## Install

```bash
chmod +x setup.sh run.sh scripts/*.sh
./setup.sh --check
./setup.sh --install all
source ~/.bashrc
./setup.sh --check
```

Install optional components separately:

```bash
./setup.sh --install pig
./setup.sh --install spark
./setup.sh --install hive
```

`all` installs Java, Hadoop, MongoDB, Pig, Spark and the Hive distribution. Hive still needs a metastore and HiveServer2 configured and running; the installer does not pretend to provision a production metastore or start a remote service automatically.

## Run

```bash
./run.sh
```

Or run an individual experiment:

```bash
./run.sh 1
./run.sh 2
./run.sh 3
./run.sh 4
./run.sh 5
./run.sh 6
./run.sh 7
./run.sh 8 hadoop
./run.sh 8 spark
```

The first run compiles the project and downloads Maven dependencies. Hadoop experiments 3, 4 and 8 require HDFS to be running and writable. Experiment 7 requires HiveServer2 reachable at `jdbc:hive2://localhost:10000/default` by default. Override with `HIVE_JDBC_URL`, `HIVE_USER`, and `HIVE_PASSWORD`.

## Experiments

1. HDFS directory/file create, list, read, download and delete using Hadoop `FileSystem` Java API.
2. Matrix multiplication using Java arrays and triple-loop multiplication.
3. Weather analysis using Hadoop Mapper/Reducer: yearly minimum, maximum, average temperature and observation count.
4. MovieLens ratings using Hadoop Mapper/Reducer: rating count and average rating per movie.
5. MongoDB Java Driver: insert sample employee documents and aggregate count/average salary by department.
6. Pig Latin processing submitted through PigServer Java API (LOCAL mode by default; set `PIG_EXEC_TYPE=MAPREDUCE` to request MapReduce mode).
7. Hive database/table/view/alter/index examples through Hive JDBC. Hive index support varies by Hive version; the index DDL is attempted and any server-side rejection is reported.
8. WordCount with Hadoop MapReduce Java or Apache Spark Java API.

## Input data

Bundled data is under `data/`: `weather.csv`, `ratings.csv`, `people_data.txt`, `employees.tsv`, and `wordcount.txt`. The runners display relevant inputs before execution.

## Java sources

All implementation classes are under `src/main/java/edu/bis701/`. There are no Python experiment implementations.

## Notes

- Hadoop uses a single-node local setup when configured that way; this is a practical lab environment, not a multi-node cluster.
- The Maven build compiles Spark code against Spark Core. Spark itself supplies runtime libraries through `spark-submit`.
- MongoDB URI can be overridden using `MONGODB_URI`.
- Do not run `hdfs namenode -format` as a routine troubleshooting step. It destroys existing HDFS namespace metadata.
