#!/bin/sh

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

sudo $(aws ecr get-login --no-include-email --region us-east-1)

sudo docker run -d \
  -v /etc/spark:/opt/spark/conf \
  --network host \
  574648240144.dkr.ecr.us-east-1.amazonaws.com/wordmaps \
  spark-class org.apache.spark.deploy.master.Master