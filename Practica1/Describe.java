package uam;
import java.io.IOException;
import java.util.*;
import java.io.DataInput;
import java.io.DataOutput;

import org.apache.hadoop.conf.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import uam.TwovalueWritable;

public class Describe {

  public static class DescribeMapper extends Mapper<Object, Text, Text, TwovalueWritable>{
    private double sum, count, min, max, val;
      
    public void map(Object key, Text value, Context context) throws IOException, InterruptedException {

			sum = 0;
			count = 0;
			min = Double.POSITIVE_INFINITY;
			max = Double.NEGATIVE_INFINITY;

      StringTokenizer itr = new StringTokenizer(value.toString());

      while (itr.hasMoreTokens()) {
				val = Double.parseDouble(itr.nextToken());
				sum += val;
				count += 1.;
				min = val < min ? val : min;
				max = val > max ? val : max;
      }

			TwovalueWritable res1 = new TwovalueWritable(sum,count);
			TwovalueWritable res2 = new TwovalueWritable(min, 0);
			TwovalueWritable res3 = new TwovalueWritable(max, 0);

			context.write(new Text("mean"), res1);
			context.write(new Text("min"), res2);
			context.write(new Text("max"), res3);
    }
  }
  
  public static class DescribeReducer extends Reducer<Text,TwovalueWritable,Text,DoubleWritable> {
    private double result, count, sum, aux0, aux1;

    public void reduce(Text key, Iterable<TwovalueWritable> values, Context context) throws IOException, InterruptedException {
			System.out.println("WEEEEE");
			System.out.println(key);
			System.out.println(values);
			if (key.equals(new Text("mean"))){
				sum = 0;
				count = 0;
		    for (TwovalueWritable val : values) {
					sum += val.getFirst();
					count += val.getSecond();
		    }
				result = sum/count;
			} else if (key.equals(new Text("min"))){
				result = Double.POSITIVE_INFINITY;
		    for (TwovalueWritable val : values) {
					result = val.getFirst() < result ? val.getFirst() : result;
		    }
			} else if (key.equals(new Text("max"))){
				result = Double.NEGATIVE_INFINITY;
		    for (TwovalueWritable val : values) {
					result = val.getFirst() > result ? val.getFirst() : result;
		    }
			}
      context.write(key, new DoubleWritable(result));
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();

    @SuppressWarnings("deprecation")
    Job job = new Job(conf, "describe");
    job.setJarByClass(Describe.class);
    job.setMapperClass(DescribeMapper.class);
    job.setReducerClass(DescribeReducer.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(TwovalueWritable.class);
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(DoubleWritable.class);

    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));

    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
