#!/bin/sh

(cd terraform && ln -s ../config/*.auto.tfvars .)

# (cd terraform && terraform apply)
# (cd ansible && pipenv run ansible-playbook deploy.yml)
