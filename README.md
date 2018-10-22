
# pyspark-deploy

This project manages the full lifecycle of a Python + Spark <-> S3 project, from local development to full-size cluster deployments on AWS. The goal is to make this totally trivial, like pushing to Heroku.

- [**Docker**](https://www.docker.com/) is used to encapsulate the application environment, making it easy to develop locally and then deploy an identical environment to a cluster.

- [**Terraform**](https://www.terraform.io/) is used to create a standalone Spark clusters on AWS. Terraform manages a completely self-contained set of resources, from the VPC up to the EC2 nodes.

- [**Ansible**](https://www.ansible.com/) is used to start the cluster. Since the environment is totally wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

Integration with a Python codebase takes ~10 minutes. Then, control the cluster with the [driver scripts](terraform/spark-cluster):

- **`create.sh`** - Start a cluster. (~2 minutes)

- **`login.sh`** - SSH into the master node, drop into tmux session, attach to bash shell on the Spark driver container. Ready to `spark-submit`.

- **`web-admin.sh`** - Open a browser tab with the Spark web admin.

- **`destroy.sh`** - Terminate cluster and all related AWS resources.

## The problem

Deploying Python code to Spark clusters can be a hassle. At minimum, you almost always need to install third-party packages. And, in many cases, it's necessary to do stuff like - upgrade to newer versions of Python, compile C extensions, download model files for packages like NLTK or SpaCy, install extra system-level software, fiddle with `PYTHONPATH`, etc.

This can be handled in various ways - cluster bootstrap scripts, pre-baked cloud AMIs - but these configurations can be brittle and hard to reproduce elsewhere. Eg, if you're using EMR, you might write a bootstrap script that configures an EMR node; but, this won't work on a development laptop running OSX, where Spark needs to be installed from scratch, etc. It's easy to end up with multiple configurations of the project, each requiring a separate layer of devops / manual setup, which can become a headache.

What you really want is just a single Docker image that can be used everywhere - on laptops during development, on CI servers, and on production clusters. But, deploying a fully Docker-ized Spark cluster also takes a bit of work. `pyspark-deploy` handles 100% of this - just extend the base Dockerfile, develop locally, and then deploy to hundreds of cores on AWS with a single command.

## Quickstart

**See [pyspark-deploy-example](https://github.com/davidmcclure/pyspark-deploy-example) for a complete example**

First, make sure you've got working installations of [Docker](https://www.docker.com/), [pipenv](https://pipenv.readthedocs.io/en/latest/), and [Terraform](https://www.terraform.io/).

Say you've got a pyspark application that looks like:

```text
project
├── job.py
├── requirements.txt
├── ...
```

### Step 1: Create a Dockerfile

First, extend the base [`dclure/spark`](docker/Dockerfile) Dockerfile, which gives a complete Python + Java + Spark environment. There are various ways to structure this, but I find it nice to separate the application code from the packaging code. Let's move the application into a `/code` directory, and add a `Dockerfile` and `docker-compose.yml` next to that:

```text
project
├── docker-compose.yml
├── Dockerfile
├── code
│   ├── job.py
│   ├── requirements.txt
│   ├── ...
```

A trivial Dockerfile might look like this:

```dockerfile
FROM dclure/spark

ADD code/requirements.txt /etc
RUN pip install -r /etc/requirements.txt

ADD code /code
WORKDIR /code
```

And, `docker-compose.yml` points to a repository on Docker Hub (doesn't need to exist yet) and mounts the `/code` directory into the container, which is essential for local development:

```yml
version: '3'

services:

  local:
    build: .
    image: dclure/pyspark-pi
    volumes:
      - ./code:/code
```

### Step 2: Develop locally

Now, we can run this container locally and develop in a standardized environment.

First, build the image:

`docker-compose build`

Run a container and attach to a bash shell:

```
docker-compose run local bash
root@9475764f5e15:/code#
```

Which then gives access to the complete Spark environment. Eg,

`spark-submit job.py`

Since the `/code` is directory is mounted as a volume, any changes we make to the source code will immediately appear in the container.

### Step 3: Create a base Docker AMI

Now, we'll deploy this to a production cluster on EC2. First, we'll create a base AMI with a Docker installation, which will then serve as the template for the cluster nodes. This step only has to be done once for each AWS account that you're deploying clusters to.

1. Add this repo as a submodule in your project. Eg, under `/deploy`:

    `git submodule add https://github.com/davidmcclure/pyspark-deploy.git deploy`

    ```text
    project
    ├── docker-compose.yml
    ├── Dockerfile
    ├── code
    │   ├── job.py
    │   ├── requirements.txt
    │   ├── ...
    ├── deploy
    │   ├── ...
    ```
