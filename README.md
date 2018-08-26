
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark project, from local development to full-size cluster deployments on AWS.

There are three basic pieces to this, and the idea is to use a best-in-class tool for each, and then connect them seamlessly:

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster. Assuming you needs some kind of custom configuration - just extend the base Dockerfile.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. The assumption here is that you're not a huge company that can afford to run a permanent cluster, and that you need to be able to start / stop clusters easily and quickly. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes. All you need is an AWS account.

- [**Ansible**](https://www.ansible.com/) is used to configure the cluster - pull Docker images, inject production config values, and start the necessary Spark daemons.

Integration with a Python codebase takes ~5 minutes. Then just run `./create.sh`, and the cluster starts in ~60 seconds. SSH into the master node and you're automatically dropped into a shell inside the Docker container, inside a tmux session, ready to submit a job.

Main goal: **Just work**. Focus 100% on the actual data engineering, never think about ops.
