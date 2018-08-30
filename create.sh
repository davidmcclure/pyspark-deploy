#!/bin/sh

ln -sf $PWD/config/terraform/*.auto.tfvars $PWD/terraform
ln -sf $PWD/config/ansible/*.yml $PWD/ansible/group_vars/all

(cd terraform && terraform apply)
(cd ansible && pipenv run ansible-playbook deploy.yml)
