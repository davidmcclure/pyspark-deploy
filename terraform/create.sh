#!/bin/sh

terraform apply
ansible-playbook deploy.yml