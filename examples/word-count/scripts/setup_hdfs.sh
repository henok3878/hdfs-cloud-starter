#!/bin/bash

# this script sets up the necessary directories for this example

USER=$(whoami)
# define HDFS input and output directories
INPUT_DIR="/user/$USER/wordcount/input"
OUTPUT_DIR="/user/$USER/wordcount/output"

# create input directory in HDFS
hdfs dfs -mkdir -p $INPUT_DIR

# create output directory in HDFS
hdfs dfs -rm -r -f $OUTPUT_DIR

# print message
echo "HDFS directories for word count example have been set up."