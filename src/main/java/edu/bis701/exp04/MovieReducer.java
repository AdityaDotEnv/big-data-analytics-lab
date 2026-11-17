package edu.bis701.exp04;
import java.io.IOException;import java.util.Locale;import org.apache.hadoop.io.*;import org.apache.hadoop.mapreduce.Reducer;
public class MovieReducer extends Reducer<Text,Text,Text,Text>{protected void reduce(Text id,Iterable<Text>vs,Context c)throws IOException,InterruptedException{double sum=0;int n=0;for(Text t:vs){sum+=Double.parseDouble(t.toString());n++;}if(n>0)c.write(id,new Text(n+"\t"+String.format(Locale.ROOT,"%.2f",sum/n)));}}
