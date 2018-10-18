#!/bin/sh

terraform init
pipenv run ansible-galaxy install -r roles.yml
