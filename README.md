
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark <-> S3 project, from local development to full-size cluster deployments on AWS. The goal is to make this totally trivial, like pushing to Heroku.

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes.

- [**Ansible**](https://www.ansible.com/) is used to start the cluster. Since the environment is totally wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

Integration with a Python codebase takes ~10 minutes. Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster. (~2 minutes)

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`web-admin.sh`** - Open a browser tab with the Spark web admin.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

One big assumption - all data sits on s3. No HDFS, etc. There are some downsides to this, but it's worth it, because everything becomes way simpler.

## The problem

Deploying Python code to Spark clusters can be a hassle. At minimum, you almost always need to install third-party packages. And, in many cases, it's necessary to do stuff like - upgrade to newer versions of Python, compile C extensions, download model files for packages like NLTK or SpaCy, install extra system-level software, fiddle with `PYTHONPATH`, etc.

This can be handled in various ways - cluster bootstrap scripts, pre-baked cloud AMIs - but these configurations can be brittle and hard to reproduce elsewhere. Eg, if you're using EMR, you might write a bootstrap script that configures an EMR node to run the project; but, this won't work on a development laptop running OSX, where Spark needs to be installed from scratch, etc. It's easy to end up with multiple configurations of the project, each requiring a separate layer of devops / manual setup, which can become a headache.

What you really want is just a single Docker image that can be used everywhere - on laptops during development, on CI servers, and on production clusters. But, deploying a fully Docker-ized Spark cluster also takes a bit of work. `pyspark-deploy` handles 100% of this - just extend the base Dockerfile (which provides a complete Java + Python + Spark environment), develop locally, and then deploy to hundreds of cores on AWS with a single command.
