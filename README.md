
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark + S3 project, from local development to full-size cluster deployments on AWS.

There are three basic pieces to this, and the idea is to use a best-in-class tool for each, and then connect them seamlessly:

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster. Assuming you need some kind of custom configuration - just extend the base Dockerfile.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. The assumption here is that you're not a huge company that can afford to run a permanent cluster, and that you need to be able to start / stop clusters easily and quickly. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes. All you need is an AWS account.

- [**Ansible**](https://www.ansible.com/) is used to configure the cluster - pull Docker images, inject production config values, and start the necessary Spark daemons.

Integration with a Python codebase takes ~5 minutes. Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster (~60s).

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`update.sh`** (TODO) - Update Docker containers on cluster nodes, restart Spark daemons to get the changes (~20s).

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

Main goal: Just work! Focus 100% on the actual data engineering, never think about ops.

## Why not EMR?

EMR is really powerful, but the developer experience is kind of under-structured, and in practice often requires a lot of added scaffolding. Many EMR examples involve a single Spark job in a single file, using no

NB: I'm not an expert with EMR, and there might be


Two (related) pain points:

- EMR nodes are generally bootstrapped with a single bash script. For complex applications / environments, this can become unwieldy - (and costly) to debug, if you basically have to spin up a cluster to 

- Python code has to be somehow made available to the cluster. Many examples push code as a single file to S3, which can then be added as a "step" in EMR. But, this doesn't scale beyond small examples. Assuming you have a non-trivial codebase -

- Related - There's no obvious way to ensure parity between the local development environment and the production environment on EMR. You basically need to set up a parallel local environment with the same packages, Python + Spark versions, etc. In practice, this is actually *more* complicated than the cluster bootstrap, since EMR provides Spark and Python, but these have to be configured from scratch in development.

One approach is to make a Docker image that installs Spark + Python, and then re-use the production EMR bootstrap script. But, this adds surface area for  - care has to be taken to ensure that the Dockerized Spark + Python match the versions provided on EMR; if the cluster bootstrap script is changed, it has to be updated in two places.


 But then, once you've got that image in hand - what if you could just literally run it in production? `pyspark-deploy` makes it easy to maintain a single Docker image with Spark + Python + your code, and

 use Docker to standardize the local environment - install Spark, and then re-use the production EMR bootstrap script. But then, once you've built that image - what if you could just literally run it in production? This is the main advantage of this approach - 100% parity between

- Vendor lock-in. Right now
