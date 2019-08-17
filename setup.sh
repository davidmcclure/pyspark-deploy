#!/bin/sh

(cd terraform && terraform init)
(cd ansible && pipenv install)
