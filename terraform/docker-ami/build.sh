#!/bin/sh

terraform apply -auto-approve
pipenv run ansible-playbook deploy.yml
terraform destroy
