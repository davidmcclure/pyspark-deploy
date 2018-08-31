
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark <-> S3 project, from local development to full-size cluster deployments on AWS.

There are three basic pieces to this, and the idea is to use a best-in-class tool for each, and then connect them seamlessly:

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster. Just extend the [base Dockerfile](docker/Dockerfile), and then [point to your project's image](config/ansible/local.yml.changeme#L5).

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes.

- [**Ansible**](https://www.ansible.com/) is used to start the cluster. Since the environment is totally wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

Integration with a Python codebase takes ~10 minutes. Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster (~60s).

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`web-admin.sh`** (TODO) - Open the Spark web admin for the master node in a browser tab.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

Main goal: Just work! Focus 100% on the actual data engineering, never think about ops.
