# Troubleshooting

- **Maven cannot download dependencies:** check network access and rerun `mvn -DskipTests package`.
- **HDFS safe mode:** inspect `hdfs dfsadmin -safemode get` and `hdfs dfsadmin -report`. Only leave safe mode after verifying DataNode health and block status. Never format an existing NameNode to fix safe mode.
- **HDFS output exists:** runners create timestamped output directories; remove only the specific old output directory if needed.
- **Pig not found:** run `./setup.sh --install pig`, then `source ~/.bashrc`.
- **Spark not found:** run `./setup.sh --install spark`, then `source ~/.bashrc`.
- **Hive JDBC connection refused:** HiveServer2 is not running or the JDBC URL is wrong. Install distribution with `./setup.sh --install hive`, configure the metastore, start HiveServer2, and set `HIVE_JDBC_URL` if necessary.
- **MongoDB connection refused:** start MongoDB or set `MONGODB_URI` to a reachable server.
- **Java version errors:** check `java -version` and `mvn -version`. Hive 4 installations generally need a modern JDK; use JDK 17 where required.
