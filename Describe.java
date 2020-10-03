package uam;
import java.io.IOException;
import java.util.*;

import org.apache.hadoop.conf.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import org.apache.hadoop.mapreduce.lib.join.TupleWritable;

public class Describe {

  public static class DescribeMapper extends Mapper<Object, Text, Text, ArrayWritable>{
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

				context.write(new Text("mean"), new ArrayWritable(new DoubleWritable[] {new DoubleWritable(sum), new DoubleWritable(count)}));
				context.write(new Text("min"), new ArrayWritable(new DoubleWritable[] {new DoubleWritable(min)}));
				context.write(new Text("max"), new ArrayWritable(new DoubleWritable[] {new DoubleWritable(max)}));
      }
    }
  }
  
  public static class DescribeReducer extends Reducer<Text,ArrayWritable,Text,DoubleWritable> {
    private double result, count, sum, aux0, aux1;

    public void reduce(Text key, Iterable<ArrayWritable> values, Context context) throws IOException, InterruptedException {
			if (key.equals("mean")){
				sum = 0;
				count = 0;
		    for (ArrayWritable val : values) {
					sum += ((DoubleWritable)(val.get()[0])).get();
					count += ((DoubleWritable)(val.get()[1])).get();
		    }
				result = sum/count;
			} else if (key.equals("min")){
				result = Double.POSITIVE_INFINITY;
		    for (ArrayWritable val : values) {
					result = ((DoubleWritable)(val.get()[0])).get() < result ? ((DoubleWritable)(val.get()[0])).get() : result;
		    }
			} else if (key.equals("max")){
				result = Double.NEGATIVE_INFINITY;
		    for (ArrayWritable val : values) {
					result = ((DoubleWritable)(val.get()[0])).get() > result ? ((DoubleWritable)(val.get()[0])).get() : result;
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
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(DoubleWritable.class);

    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));

    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
