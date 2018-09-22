
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark <-> S3 project, from local development to full-size cluster deployments on AWS. Extracted from work at the [Open Syllabus Project](http://explorer.opensyllabusproject.org/) and the [Laboratory for Social Machines](http://socialmachines.org/) at the MIT Media Lab, where this rig is used to chew though a corpus of ~20 billion tweets.

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster. Just extend the [base Dockerfile](docker/Dockerfile), and then [point to your project's image](config/ansible/local.yml.changeme#L5).

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes.

- [**Ansible**](https://www.ansible.com/) is used to start the cluster. Since the environment is totally wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

#### 🚀 Integration with a Python codebase takes ~10 minutes:

1. Add this repo as a submodule to your project.

1. Extend the [base Dockerfile](docker/Dockerfile), which provides a complete Spark 2.3 + Python 3 environment. (Or write something totally custom). Push to Docker Hub.

1. Edit [`config/ansible/local.yml`](config/ansible/local.yml.changeme#L5), point to your repo on Docker Hub.

#### 🚀 Then, control the cluster with the top-level scripts:

- **`create.sh`** - Start a cluster (~60s).

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

One big assumption - all data sits on s3. No HDFS, etc. There are some downsides to this, but it's worth it, because everything becomes way simpler.

## The problem

One difficulty of writing Spark applications in Python is that there isn't a clear story about how the Python code + environment should be deployed to clusters. In Scala / Java, this isn't an issue - you can just wrap everything up as a JAR and ship it off as a single file. In Python, though, packaging and configuration is much more complex. At minimum, you almost always need to install custom pip packages. And, in many cases, stuff like - upgrade to newer versions of Python, download model files for packages like NLTK or SpaCy, install extra system-level software, fiddle with `PYTHONPATH` or other ENV variables, etc.

Related to this - even if everything works on the cluster (via something like EMR bootstrap scripts, or a custom AMI), it's often not clear how to keep things consistent between the cluster and the dev environments where code actually gets written and tested. Even with small teams, it's annoying for everyone to have to manually install a local Spark distribution and set up the project environment.

Of course, Docker solves all of these problems! But, deploying a Docker-ized Spark cluster also takes a bit of work. `pyspark-deploy` handles 100% of this - just write a Dockerfile, develop locally, and then deploy to hundreds of cores on AWS with a single command.
