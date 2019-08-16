
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark <-> S3 project, from local development to full-size cluster deployments on AWS. The goal is to make this totally trivial, like pushing to Heroku.

- [**Docker**](https://www.docker.com/) is used to wrap up a complete Python + Java + Spark environment, making it easy to develop locally and then deploy an identical environment to a cluster. Just extent the base image, and add you code + config.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark cluster on AWS.

- [**Ansible**](https://www.ansible.com/) is used to start the cluster. Since the application environment is totally wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

## Quickstart

**See [pyspark-deploy-example](https://github.com/davidmcclure/pyspark-deploy-example) for a complete example**
