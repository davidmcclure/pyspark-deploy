#!/usr/bin/env bash

# Use ipython for driver.
PYSPARK_DRIVER_PYTHON=ipython

# So that links work properly in Spark admin.
SPARK_PUBLIC_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname || wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`

# AWS credentials.
AWS_ACCESS_KEY_ID={{aws_access_key_id}}
AWS_SECRET_ACCESS_KEY={{aws_secret_access_key}}

# Avoid too-many-open-files errors.
ulimit -n 100000

# Prevent SpaCy from spawning threads.
OPENBLAS_NUM_THREADS=1

# Use common hash seed across nodes (needed for reduceByKey).
PYTHONHASHSEED=1

SPARK_WORKER_DIR=/data/work

# W&B key.
WANDB_API_KEY={{wandb_api_key}}
