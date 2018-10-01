#!/bin/sh

ln -sf $PWD/config/*.auto.tfvars $PWD/terraform/spark-cluster
ln -sf $PWD/config/*.yml $PWD/ansible/group_vars/all

(cd terraform/spark-cluster && terraform apply)
(cd ansible && pipenv run ansible-playbook deploy.yml)
