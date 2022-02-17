#!/bin/sh

ssh -o StrictHostKeyChecking=no -t \
  ubuntu@`terraform output -raw master_dns` \
  sh spark-bash.sh