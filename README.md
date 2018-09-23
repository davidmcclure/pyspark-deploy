
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark <-> S3 project, from local development to full-size cluster deployments on AWS. The goal is to make this totally trivial, like pushing to Heroku.

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes.

- [**Ansible**](https://www.ansible.com/) is used to start the cluster. Since the environment is totally wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

Integration with a Python codebase takes ~10 minutes:

1. Add this repo as a submodule to your project.

1. Extend the [base Dockerfile](docker/Dockerfile), which provides a complete Spark 2.3 + Python 3 environment. (Or write something totally custom). Push to Docker Hub.

1. Edit [`config/ansible/local.yml`](config/ansible/local.yml.changeme#L5), point to your repo on Docker Hub.

Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster (~60s).

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

One big assumption - all data sits on s3. No HDFS, etc. There are some downsides to this, but it's worth it, because everything becomes way simpler.

## The problem

One difficulty of writing Spark applications in Python is that deploying Python code to clusters can be a hassle. In Scala / Java, this isn't an issue - you can just wrap everything up as a JAR and ship it off as a single file. In Python, though, packaging and configuration is much more complex. At minimum, you almost always need to install third-party packages. And, in many cases, stuff like - upgrade to newer versions of Python, compile C extensions, download model files for packages like NLTK or SpaCy, install extra system-level software, fiddle with `PYTHONPATH` or other ENV variables, etc.

The recommended solutions for this are often kind of unrealistic. The official EMR docs, for example, have you upload a single Python file to S3 (presumably just using the standard library), and then manually add the script as a "step" in the EMR admin - but this doesn't scale beyond trivial examples. More feasible - you could use a cluster bootstrap script to checkout the code and build the environment. But, for complex projects, the reality is that these builds can become slow and fragile - it's not the kind of thing you want to do on every node in a cluster, every time you start a cluster, if you can avoid it. Another approach is to pre-bake a custom AMI, but this adds friction to the workflow - the AMI has to be continually kept in sync with the local development environments, re-snapshotted before job runs, etc.

What you really want is just a single Docker image that can be used everywhere - on laptops during development, on CI servers, and on production clusters. But, deploying a fully Docker-ized Spark cluster also takes a bit of work. `pyspark-deploy` handles 100% of this - just write a Dockerfile, develop locally, and then deploy to hundreds of cores on AWS with a single command.
