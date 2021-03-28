#!/bin/sh

terraform apply
poetry run ansible-playbook deploy.yml