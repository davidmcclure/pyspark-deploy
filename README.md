
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark + S3 project, from local development to full-size cluster deployments on AWS.

There are three basic pieces to this, and the idea is to use a best-in-class tool for each, and then connect them seamlessly:

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster. Assuming you need some kind of custom configuration - just extend the base Dockerfile.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes. All you need is an AWS account.

- [**Ansible**](https://www.ansible.com/) is used to configure the cluster - pull Docker images, inject production config values, and start the necessary Spark daemons.

Integration with a Python codebase takes ~5 minutes. Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster (~60s).

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`web-admin.sh`** (TODO) - Open the Spark web admin for the master node in a browser tab.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

Main goal: Just work! Focus 100% on the actual data engineering, never think about ops.
