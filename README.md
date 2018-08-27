
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark + S3 project, from local development to full-size cluster deployments on AWS.

There are three basic pieces to this, and the idea is to use a best-in-class tool for each, and then connect them seamlessly:

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster. Assuming you needs some kind of custom configuration - just extend the base Dockerfile.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. The assumption here is that you're not a huge company that can afford to run a permanent cluster, and that you need to be able to start / stop clusters easily and quickly. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes. All you need is an AWS account.

- [**Ansible**](https://www.ansible.com/) is used to configure the cluster - pull Docker images, inject production config values, and start the necessary Spark daemons.

Integration with a Python codebase takes ~5 minutes. Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster (~60s).

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`update.sh`** [TODO] - Update Docker containers on cluster nodes, restart Spark daemons to get the changes (~20s). Makes it easy to push updates to a running cluster.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

Main goal: Just work. Focus 100% on the actual data engineering, never think about ops.
