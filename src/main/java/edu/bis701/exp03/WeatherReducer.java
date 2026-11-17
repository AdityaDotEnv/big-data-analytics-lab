package edu.bis701.exp03;
import java.io.IOException;import java.util.Locale;import org.apache.hadoop.io.*;import org.apache.hadoop.mapreduce.Reducer;
public class WeatherReducer extends Reducer<Text,Text,Text,Text>{protected void reduce(Text y,Iterable<Text>vs,Context c)throws IOException,InterruptedException{int min=Integer.MAX_VALUE,max=Integer.MIN_VALUE,n=0;long sum=0;for(Text t:vs){int x=Integer.parseInt(t.toString());min=Math.min(min,x);max=Math.max(max,x);sum+=x;n++;}if(n>0)c.write(y,new Text(min+"\t"+max+"\t"+String.format(Locale.ROOT,"%.2f",(double)sum/n)+"\t"+n));}}
