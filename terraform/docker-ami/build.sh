#!/bin/sh

terraform apply
pipenv run ansible-playbook deploy.yml
terraform destroy
