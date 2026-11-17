
package edu.bis701.exp06;

import org.apache.pig.ExecType;
import org.apache.pig.PigServer;
import org.apache.pig.data.Tuple;

import java.util.Iterator;
import java.util.Properties;

public class PigLatinExperiment {

    public static void main(String[] args) throws Exception {

        String input = args.length > 0
                ? args[0]
                : "data/people_data.txt";

        String mode = System.getenv().getOrDefault(
                "PIG_EXEC_TYPE", "LOCAL");

        ExecType type = "MAPREDUCE".equalsIgnoreCase(mode)
                ? ExecType.MAPREDUCE
                : ExecType.LOCAL;

        PigServer pig = new PigServer(type, new Properties());

        try {
            String safeInput = input
                    .replace("\\", "\\\\")
                    .replace("'", "\\'");

            pig.registerQuery(
                "people = LOAD '" + safeInput +
                "' USING PigStorage(',') AS " +
                "(name:chararray, age:int, city:chararray);"
            );

            pig.registerQuery(
                "adults = FILTER people BY age >= 30;"
            );

            pig.registerQuery(
                "grouped = GROUP adults BY city;"
            );

            pig.registerQuery(
                "counts = FOREACH grouped GENERATE " +
                "group AS city, COUNT(adults) AS total;"
            );

            pig.registerQuery(
                "ordered = ORDER counts BY total DESC;"
            );

            System.out.println("Pig Latin result:");

            Iterator<Tuple> rows = pig.openIterator("ordered");

            while (rows.hasNext()) {
                System.out.println(rows.next());
            }

        } finally {
            pig.shutdown();
        }
    }
}

