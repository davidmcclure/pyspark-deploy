#!/bin/sh

pipenv install

terraform init cluster

ansible-galaxy install -r roles.yml
