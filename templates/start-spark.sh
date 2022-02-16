#!/bin/sh

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${ecr_server}

docker run -d \
  --name spark \
  -v /etc/spark:/opt/spark/conf \
  -v /data:/data \
  -p 8080:8080 \
  ${ecr_server}/${ecr_repo} \
  spark-class org.apache.spark.deploy.master.Master