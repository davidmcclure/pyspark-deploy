
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
    image: dclure/pyspark-example
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

Now, we'll deploy this to a production cluster on EC2. First, we'll create a base AMI with a Docker installation, which will then serve as the template for the cluster nodes. In theory, we could also install Docker on each node every time we put up a cluster. But, since this configuration is always the same, by pre-baking an AMI once at the start we can shave some time off of the cluster deployments, and also make them more reliable.

**Important**: This step only has to be done once for each AWS account that you're deploying clusters to.

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
    |   ├── Pipfile
    |   ├── Pipfile.lock
    |   ├── README.md
    |   ├── docker
    |   ├── terraform
    ```

1. Change down into `/deploy` and install dependencies with `pipenv install`.

1. Change into `/deploy/terraform/docker-ami` and run `./setup.sh`, which initializes the Terraform project.

1. Make sure you've got correctly configured AWS credentials (eg, via `aws configure`).

1. Run **`./build.sh`** which will create a sandbox instance on EC2, configure Docker, create an AMI. At the end, when prompted, type `yes` to confirm that Terraform should destroy the node. This script will produce a (.gitignored) file in the working directory called `docker-ami.auto.tfvars`, which contains the ID of the new AMI. Eg,

    ```hcl
    docker_ami = "ami-XXX"
    ```

1. Copy this file into the `spark-cluster` directory, which sits adjacent to `docker-ami`:

    `cp docker-ami.auto.tfvars ../spark-cluster`

    Terraform automatically loads variables from files with the `*.auto.tfvars` extension, so this file will override the `docker_ami` variable, defined in `spark-cluster/variables.tf`.

### Step 4: Deploy a cluster

Now, the fun part! First, we need to make sure the Docker image for the application is available in a web-facing Docker Hub repository, so that it can be pulled onto the cluster nodes.

1. In `docker-compose.yml`, we reference a Hub repository in the `image` key.

    ```yml
    version: '3'

    services:

      local:
        build: .
        image: dclure/pyspark-example <---
        volumes:
          - ./code:/code
    ```

    Create this repository, if it doesn't already exist.

1. Push the image with `docker-compose push`.

1. Change into `/deploy/terraform/spark-cluster` and run `./setup.sh`.

1. Copy `local.yml.changeme` -> `local.yml` and fill in the image name and AWS credentials. Eg:

    ```yml
    ---
    spark_docker_image: dclure/pyspark-example
    aws_access_key_id: XXX
    aws_secret_access_key: XXX
    ```

    **Important**: `local.yml` is .gitignored, so even if you're working with a fork of this repository and committing changes, this file shouldn't get tracked. But, out of an abundance of caution, I use `ansible-vault` to [encrypt the values of the two AWS credential keys](https://docs.ansible.com/ansible/latest/user_guide/vault.html#encrypt-string-for-use-in-yaml). This way, even if this file gets accidentally committed and pushed to a public-facing repo, the secrets won't leak.

1. Check the cluster settings in `variables.tf`. By default, `pyspark-deploy` puts up a smaller cluster - a `c5.xlarge` master node (on-demand) and 2x `c3.8xlarge` workers (spot requests, $0.48). To customize the deploy, add a file called `local.auto.tfvars` and override settings. Eg, 10x workers:

    ```hcl
    worker_count = 10
    ```

    This will give 320 cores and 580g of ram for just over $5/hour, which is great.
