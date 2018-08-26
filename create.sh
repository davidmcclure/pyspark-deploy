#!/bin/sh

(cd terraform && terraform apply)
(cd ansible && pipenv run ansible-playbook deploy.yml)
