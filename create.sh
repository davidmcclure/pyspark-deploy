#!/bin/sh

(cd terraform && terraform apply -auto-approve)
(cd ansible && pipenv run ansible-playbook deploy.yml)
