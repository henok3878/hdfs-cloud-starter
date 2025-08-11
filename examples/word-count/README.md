# Hadoop MapReduce Word Count Example

This project demonstrates a simple word count example using MapReduce with Python and Hadoop Streaming. The implementation consists of a mapper and a reducer.

## Project Structure

```
examples/
└── word-count/
    ├── src/
    │   ├── mapper.py       # mapper script
    │   └── reducer.py      # reducer script
    ├── data/
    │   └── input.txt       # sample input data for the word count job
    ├── scripts/
    │   ├── run_wordcount.sh # script to submit the MapReduce job
    │   └── setup_hdfs.sh    # script to set up HDFS directories
    └── README.md
```

## Prerequisites

- Hadoop installed and configured
- Python installed
- Access to a Hadoop cluster

Note: You can use the provided `hdfs-deploy.sh` script at the repo root to automate Hadoop cluster setup with Terraform and Ansible.

- Copy `examples/word-count` folder on your Hadoop master node.
  > To copy just this folder from GitHub, run:
  >
  > ```bash
  > git clone --depth 1 --filter=blob:none --sparse https://github.com/henok3878/hdfs-cloud-starter.git
  > cd hdfs-cloud-starter
  > git sparse-checkout set examples/word-count
  > ```

## How to Run the Word Count Job

1. **Set up HDFS directories**: Run the `setup_hdfs.sh` script to create the necessary directories in HDFS.

   ```bash
   cd examples/word-count/scripts
   ./setup_hdfs.sh
   ```

2. **Submit the MapReduce job**: Execute the `run_wordcount.sh` script to run the word count job.

   ```bash
   ./run_wordcount.sh
   ```

## Code Overview

- **mapper.py**: Reads input data line by line, splits each line into words, and emits each word with a count of 1.
- **reducer.py**: Aggregates the counts for each word and emits the total count for each word.
