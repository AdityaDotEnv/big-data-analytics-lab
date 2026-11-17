#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
CP="$ROOT/target/classes:$ROOT/target/dependency/*"
HADOOP_CP=""

build_project() {
  command -v mvn >/dev/null || { echo "Maven is required. Run ./setup.sh --install common" >&2; return 1; }
  echo "Compiling Java experiments..."
  mvn -q -DskipTests package
}

hadoop_classpath() {
  if command -v hadoop >/dev/null 2>&1; then hadoop classpath --glob 2>/dev/null || hadoop classpath; fi
}

run_hadoop_job() {
  local main="$1" input="$2" output="$3"
  command -v hadoop >/dev/null || { echo "Hadoop is not installed or not on PATH." >&2; return 1; }
  hdfs dfs -mkdir -p "$(dirname "$input")"
  hdfs dfs -put -f "$ROOT/$4" "$input"
  if hdfs dfs -test -e "$output"; then hdfs dfs -rm -r -skipTrash "$output"; fi
  echo "HDFS input: $input"
  hdfs dfs -cat "$input"
  echo "Running $main..."
  hadoop jar "$ROOT/target/bis701-big-data-lab-1.0.0.jar" "$main" "$input" "$output"
  echo "Result:"
  hdfs dfs -cat "$output/part-r-00000"
}

run_one() {
  local n="$1" mode="${2:-}"
  build_project
  case "$n" in
    1)
      command -v hadoop >/dev/null || { echo "Hadoop is required."; return 1; }
      java -cp "$CP:$(hadoop_classpath)" edu.bis701.exp01.HDFSOperations
      ;;
    2) java -cp "$CP" edu.bis701.exp02.MatrixMultiplication ;;
    3) run_hadoop_job edu.bis701.exp03.WeatherAnalysis /bis701/weather/input/weather.csv "/bis701/weather/output-$(date +%Y%m%d%H%M%S)" data/weather.csv ;;
    4) run_hadoop_job edu.bis701.exp04.MovieLensAnalysis /bis701/movielens/input/ratings.csv "/bis701/movielens/output-$(date +%Y%m%d%H%M%S)" data/ratings.csv ;;
    5)
      command -v mongod >/dev/null || echo "Warning: mongod executable not found; MongoDB service may be remote."
      java -cp "$CP" edu.bis701.exp05.MongoAggregation
      ;;
    6)
      command -v pig >/dev/null || { echo "Apache Pig is missing. Install it with ./setup.sh --install pig"; return 1; }
      java -cp "$CP:$(hadoop_classpath):${PIG_HOME:-$HOME/.local/opt/pig}/lib/*" edu.bis701.exp06.PigLatinExperiment "$ROOT/data/people_data.txt"
      ;;
    7)
      command -v beeline >/dev/null || { echo "Hive client is missing. Install it with ./setup.sh --install hive"; return 1; }
      java -cp "$CP" edu.bis701.exp07.HiveExperiment
      ;;
    8)
      case "$mode" in
        hadoop|1) run_hadoop_job edu.bis701.exp08.HadoopWordCount /bis701/wordcount/input/input.txt "/bis701/wordcount/output-$(date +%Y%m%d%H%M%S)" data/wordcount.txt ;;
        spark|2)
          command -v spark-submit >/dev/null || { echo "Apache Spark is missing. Install it with ./setup.sh --install spark"; return 1; }
          echo "Input text:"; cat data/wordcount.txt
          spark-submit --class edu.bis701.exp08.SparkWordCount --master 'local[*]' "$ROOT/target/bis701-big-data-lab-1.0.0.jar" "$ROOT/data/wordcount.txt"
          ;;
        *) echo "Choose hadoop or spark." >&2; return 2 ;;
      esac
      ;;
  esac
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    --check) exec "$ROOT/setup.sh" --check ;;
    --install) exec "$ROOT/setup.sh" --install "${2:-all}" ;;
    [1-8]) run_one "$1" "${2:-}"; exit $? ;;
    -h|--help) echo "Usage: ./run.sh [1-8 [hadoop|spark]] | --check | --install COMPONENT"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
fi
while true; do
  echo
  echo "========== BIS701 BIG DATA ANALYTICS LAB =========="
  printf '%s\n' ' 1) HDFS file and directory operations' ' 2) Matrix multiplication' ' 3) Weather data analysis' ' 4) MovieLens ratings analysis' ' 5) MongoDB aggregation' ' 6) Pig Latin data processing' ' 7) Hive database, table, view and index operations' ' 8) WordCount (Hadoop / Spark)' ' 9) Check dependencies' '10) Install dependencies' ' 0) Exit'
  read -r -p 'Select: ' choice || exit 0
  case "$choice" in
    0) exit 0 ;;
    9) "$ROOT/setup.sh" --check ;;
    10) "$ROOT/setup.sh" --install all ;;
    8) read -r -p 'Choose implementation [1 Hadoop / 2 Spark]: ' mode; [[ "$mode" == 1 ]] && run_one 8 hadoop || { [[ "$mode" == 2 ]] && run_one 8 spark || echo 'Invalid choice.'; } ;;
    [1-7]) run_one "$choice" ;;
    *) echo 'Invalid choice.' ;;
  esac
done
