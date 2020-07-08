
# pyspark-deploy

This project automates the process of provisioning and deploying a standalone Spark cluster on EC2 spot instances.

- [**Docker**](https://www.docker.com/) is used to wrap up a complete Python + Java + Spark environment, making it easy to develop locally and then deploy an identical environment to a cluster. Just extend the base image, and add you code + config.

- [**Terraform**](https://www.terraform.io/) is used to provision instances on AWS.

- [**Ansible**](https://www.ansible.com/) is used to configure the cluster. Since the application environment is wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

## Usage

1. On the host machine, install:

    - [Poetry](https://python-poetry.org/)
    - [Terraform](https://www.terraform.io/) (>= 0.12.28)

1. Add this repository as a submodule in your project. Eg, under `/deploy` at the root level.

1. Change into the directory, and run `./setup.sh`. This will initialize the Terraform project and install the Python dependencies.

TODO