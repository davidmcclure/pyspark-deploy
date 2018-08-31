#!/bin/sh

# Init Terraform.
(cd terraform && terraform init)

# Init Ansible env, install roles.
(cd ansible && pipenv install)
(cd ansible && pipenv run ansible-galaxy install -r roles.yml)

# TODO: Create local config files, log instructions.
