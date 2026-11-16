# Experiment 1 — Hadoop installation and configuration

This runner checks the native Hadoop installation, Java, HDFS/YARN commands and daemon status. It does not blindly overwrite configuration or format HDFS.

```bash
./run.sh
```

If Hadoop is absent, follow `docs/UBUNTU_SETUP.md`. Set `HADOOP_HOME` if Hadoop is installed outside the standard PATH.
