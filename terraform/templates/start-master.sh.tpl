#!/bin/sh

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

# TODO: Install Docker here?

# TODO: Need to update to new format if we bump the base image.
sudo $(aws ecr get-login --no-include-email --region us-east-1)

# TODO: driver + worker
# TODO: Mount /data
# TODO: Set runtime
sudo docker run -d \
  -v /etc/spark:/opt/spark/conf \
  --network host \
  ${docker_image} \
  spark-class org.apache.spark.deploy.master.Master