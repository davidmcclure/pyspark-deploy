#!/bin/sh

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${ecr_server}

docker run -d \
  --name spark \
  --network host \
  -v /data:/data \
  -v /etc/spark/conf:/opt/spark/conf \
  -p 8080:8080 \
  ${ecr_server}/${ecr_repo} \
  ${
    master_private_ip != null ?
    "spark-class org.apache.spark.deploy.worker.Worker spark://${master_private_ip}:7077" :
    "spark-class org.apache.spark.deploy.master.Master"
  }