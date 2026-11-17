package edu.bis701.exp03;
import java.io.IOException;import org.apache.hadoop.io.*;import org.apache.hadoop.mapreduce.Mapper;
public class WeatherMapper extends Mapper<LongWritable,Text,Text,Text>{protected void map(LongWritable k,Text v,Context c)throws IOException,InterruptedException{String s=v.toString().trim();if(s.isEmpty()||s.toLowerCase().startsWith("date"))return;String[]p=s.split("\\s*,\\s*");if(p.length<3)return;try{c.write(new Text(p[0].substring(0,4)),new Text(p[2]));}catch(Exception e){System.err.println("Invalid weather row: "+s);}}}
