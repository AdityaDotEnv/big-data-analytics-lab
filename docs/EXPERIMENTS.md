# Experiment reference

| No. | Main Java class | Runtime | Result |
|---|---|---|---|
| 1 | `edu.bis701.exp01.HDFSOperations` | HDFS | HDFS operations and retrieved local file |
| 2 | `edu.bis701.exp02.MatrixMultiplication` | JVM | Product matrix |
| 3 | `edu.bis701.exp03.WeatherAnalysis` | Hadoop MapReduce | Yearly temperature statistics |
| 4 | `edu.bis701.exp04.MovieLensAnalysis` | Hadoop MapReduce | Count and average rating by movie |
| 5 | `edu.bis701.exp05.MongoAggregation` | MongoDB | Department employee count and average salary |
| 6 | `edu.bis701.exp06.PigLatinExperiment` | Apache Pig via PigServer | Adult employee count by city |
| 7 | `edu.bis701.exp07.HiveExperiment` | HiveServer2 via JDBC | Hive DDL/view/query operations |
| 8 | `edu.bis701.exp08.HadoopWordCount` / `SparkWordCount` | Hadoop or Spark | Token frequencies |

## Input schemas

- Weather: `date,condition,temperature,humidity,wind,rain`
- Ratings: `userId,movieId,rating,timestamp`
- Pig people: `name,age,city`
- Hive employees: tab-separated `id,name,age,city,salary`
