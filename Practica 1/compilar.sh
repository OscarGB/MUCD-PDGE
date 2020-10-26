#!/bin/bash

file=$1
jar=$2

HADOOP_CLASSPATH=/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/*
echo $HADOOP_CLASSPATH

rm -rf ${file}
mkdir -p ${file}

if [ ${file} == "Describe" ];
then 
	rm -rf TwovalueWritable
	mkdir -p TwovalueWritable
	javac -classpath $HADOOP_CLASSPATH -d ${file} ${file}.java TwovalueWritable.java
else
	javac -classpath $HADOOP_CLASSPATH -d ${file} ${file}.java
fi

jar -cvf ${jar}.jar -C ${file}/ .
