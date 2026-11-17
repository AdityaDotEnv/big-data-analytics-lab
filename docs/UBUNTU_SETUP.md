# Ubuntu / Linux Mint setup

1. Install supported components: `./setup.sh --install all`.
2. Reload environment: `source ~/.bashrc`.
3. Verify tools: `./setup.sh --check`.
4. Configure and start HDFS according to `core-site.xml` and `hdfs-site.xml`; for single-node use, ensure localhost SSH works if your Hadoop scripts require it.
5. Start MongoDB: `sudo systemctl enable --now mongod` (service name may differ by package).
6. For Hive, configure a metastore and HiveServer2. The JDBC client expects HiveServer2 on port 10000 by default.
7. Run `./run.sh`.

Pig and Spark are installed under `~/.local/opt` with symlinks in `~/.local/bin`. The installer appends their environment variables to `~/.bashrc` once. Open a new terminal or run `source ~/.bashrc`.
