
# pyspark-deploy

This project automates the process of provisioning and deploying a standalone Spark cluster on EC2 spot instances. This is designed with small teams / organizations in mind, where there isn't budget to maintain permanent infrastructure - everything is optimized around making it easy to spin up a cluster, run jobs, and then immediately terminate the AWS resources on completion. 

Once the Docker image is pushed to ECR, deploys generally take ~2 minutes.

- [**Docker**](https://www.docker.com/) is used to wrap up a complete Python + Java + Spark environment, making it easy to develop locally and then deploy an identical environment to a cluster. Just extend the base image and add you code. (Or, if needed, build a totally custom image from scratch.)

- [**Terraform**](https://www.terraform.io/) is used to provision instances on AWS.

- [**Ansible**](https://www.ansible.com/) is used to configure the cluster. Since the application environment is wrapped up in Docker, Ansible just pulls the image on the nodes, injects production config values, and starts the Spark services.

## Setup

1. On the host machine, install:

    - [Poetry](https://python-poetry.org/)
    - [Terraform](https://www.terraform.io/) (>= 0.12.28)

1. Add this repository as a submodule in your project. Eg, under `/deploy` at the root level.

1. Change into the directory, and run `./setup.sh`. This will initialize the Terraform project and install the Python dependencies.

1. Add a `cluster.yml` file in the parent directory - `cp config.yml.changeme ../config.yml` (the root directory of your project, tracked in git). Fill in values for the required fields:

    ```python
    aws_vpc_id: str
    aws_subnet_id: str
    aws_ami: str
    public_key_path: str
    docker_image: str
    aws_access_key_id: str
    aws_secret_access_key: str
    ```

    For full reference on the supported fields, see the `ClusterConfig` class in `cluster.py`, a [pydantic](https://pydantic-docs.helpmanual.io/) model that defines the configuration schema.

    **Note:** pyspark-deploy assumes the Docker image is pushed to an ECR repository, and that the provided AWS keypair has permissions to pull the image.

    **Note:** For secret values like `aws_access_key_id`, it's recommended to use Ansible vault to encrypt the values. (See - [Single Encrypted Variable](https://docs.ansible.com/ansible/2.3/playbooks_vault.html#single-encrypted-variable)). pyspark-deploy will automatically decrypt these values at deploy time. If you do this, it generally also makes sense to put the vault password in a file (eg, `~/.vault-pw.txt`), and then set the `ANSIBLE_VAULT_PASSWORD_FILE` environment variable. This avoids having to manually enter the password each time a cluster is created.

1. In `/deploy`, run `poetry shell` to activate the env.

## Usage

Control the cluster with `./cluster.py`:

```bash
Usage: cluster.py [OPTIONS] COMMAND [ARGS]...

Options:
  --help  Show this message and exit.

Commands:
  create     Start a cluster.
  destroy    Destroy the cluster.
  login      SSH into the master node.
  web-admin  Open the Spark web UI.
```

Generally the workflow looks like:

- Develop locally in Docker. When ready to deploy, push the Docker image to the ECR repository specified in `docker_image`.
- Run `./cluster.py create`, then `./cluster.py login` once the cluster is up.
- Run jobs.
- Tear down with `./cluster.py destroy`.

## Profiles

It's common to need a handful of cluster "profiles" for a single project. Eg, you might have some jobs / workflows that need a small number of modest worker instances; but other jobs that need a large number of big workers, and others that need GPU workers. To support this, the `cluster.yml` file can container any number of named "profiles," which can provide override values that customize the cluster loadout.

```yaml
profiles:

  cpu_small:
    worker_count: 3
    worker_instance_type: m5a.8xlarge
    worker_spot_price: 0.8
    executor_memory: 100g

  cpu_big:
    worker_count: 10
    worker_instance_type: r5n.16xlarge
    worker_spot_price: 1.6
    executor_memory: 480g

  gpu:
    worker_count: 5
    worker_instance_type: p3.2xlarge
    worker_docker_runtime: nvidia
    worker_spot_price: 1.0
    executor_memory: 40g
```

Then, when creating a cluster, just pass the profile name, and these values will be merged into the configuration used to deploy the cluster:

`./cluster.py create gpu`