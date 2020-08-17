#!/bin/sh

exec poetry run python ./pyspark_deploy.py "$@"