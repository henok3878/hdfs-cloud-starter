#!/bin/bash

set -e 

USER=$(whoami)
# set the input and output paths
INPUT_PATH=/user/$USER/wordcount/input
OUTPUT_PATH=/user/$USER/wordcount/output

# remove the output directory if it already exists
hdfs dfs -rm -r $OUTPUT_PATH

# find hadoop streaming jar
HADOOP_STREAMING_JAR=$(find $HADOOP_HOME -name "hadoop-streaming*.jar" | head -1)
if [ -z "$HADOOP_STREAMING_JAR" ]; then
    echo "ERROR: Hadoop streaming jar not found in $HADOOP_HOME"
    exit 1
fi

# run the Hadoop streaming job
hadoop jar $HADOOP_STREAMING_JAR \
    -input $INPUT_PATH \
    -output $OUTPUT_PATH \
    -mapper "python3 src/mapper.py" \
    -reducer "python3 src/reducer.py" \
    -file src/mapper.py \
    -file src/reducer.py

# display the output
echo "Job completed...Results:"
hdfs dfs -cat $OUTPUT_PATH/part-00000