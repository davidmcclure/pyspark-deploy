
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

One big assumption - all data sits on s3. No HDFS, etc. There are some downsides to this, but it's worth it, because everything becomes way simpler.

## The problem

Deploying Python code to Spark clusters can be a hassle. At minimum, you almost always need to install third-party packages. And, in many cases, it's necessary to do stuff like - upgrade to newer versions of Python, compile C extensions, download model files for packages like NLTK or SpaCy, install extra system-level software, fiddle with `PYTHONPATH`, etc.

This can be handled in various ways - cluster bootstrap scripts, pre-baked cloud AMIs - but these configurations can be brittle and hard to reproduce elsewhere. Eg, if you're using EMR, you might write a bootstrap script that configures an EMR node; but, this won't work on a development laptop running OSX, where Spark needs to be installed from scratch, etc. It's easy to end up with multiple configurations of the project, each requiring a separate layer of devops / manual setup, which can become a headache.

What you really want is just a single Docker image that can be used everywhere - on laptops during development, on CI servers, and on production clusters. But, deploying a fully Docker-ized Spark cluster also takes a bit of work. `pyspark-deploy` handles 100% of this - just extend the base Dockerfile, develop locally, and then deploy to hundreds of cores on AWS with a single command.

## Quickstart

**See [pyspark-deploy-example](https://github.com/davidmcclure/pyspark-deploy-example) for a complete example**

First, make sure you've got working installations of [Docker](https://www.docker.com/), [pipenv](https://pipenv.readthedocs.io/en/latest/), and [Terraform](https://www.terraform.io/).

Then - say you've got a pyspark application that looks like:

```text
project
├── job.py
├── requirements.txt
```

Where `job.py` is a Spark application - here, the canonical pi-estimation example, but wrapped up as a click application:

```python
import click
import random

from pyspark import SparkContext


def inside(p):
    """Randomly sample a point in the unit square, return true if the point is
    inside a circle of r=1 centered at the origin.
    """
    x, y = random.random(), random.random()
    return x*x + y*y < 1


@click.command()
@click.argument('n', type=int, default=1e9)
def main(n):
    """Estimate pi by sampling a billion random points.
    """
    sc = SparkContext.getOrCreate()

    count = sc.parallelize(range(n)).filter(inside).count()
    pi = 4 * count / n

    print(pi)


if __name__ == '__main__':
    main()
```

And `requirements.txt` installs click and ipython:

```text
click
ipython
```

This is obviously a simplest possible example - the codebase could be arbitrarily large / complex, and organized in any way.

### Step 1: Create a Dockerfile

First, we'll extend the base `dclure/spark` Dockerfile, which gives a complete Python + Java + Spark environment. There are various ways to structure this, but I find it nice to explicitly separate the application code from the packaging code. Let's move the application into a `/code` directory, and put the Dockerfile next to that:

```text
project
├── Dockerfile
├── code
│   ├── job.py
│   ├── requirements.txt
```

In this case, the Dockerfile can be trivial - just add the code and do the `pip install`:

```dockerfile
FROM dclure/spark

ADD code/requirements.txt /etc
RUN pip install -r /etc/requirements.txt

ADD code /code
WORKDIR /code
```

Again, in reality, this could be arbitrarily complex. And, if you want total control over the Python or Spark installation, you can write a totally custom Dockerfile instead of extending the `dclure/spark` base image. As long as Spark is installed at `/opt/spark`, the deployment harness will work without any changes. (And, even this can be changed - you'd just need to provide an override for the `spark_home` variable, described below.)

Let's also add a `docker-compose.yml` file in the top-level directory, which points to a repository on Docker Hub (doesn't need to exist yet) and mounts the `/code` directory into the container, which is essential for local development:

```yml
version: '3'

services:

  local:
    build: .
    image: dclure/pyspark-pi
    volumes:
      - ./code:/code
```

So, now we've got:

```text
project
├── docker-compose.yml
├── Dockerfile
├── code
│   ├── job.py
│   ├── requirements.txt
```

## Step 2: Develop locally

Now, let's run the image locally and test the job. First, build the image with:

`docker-compose build`

Then run a container and attach to a bash shell:

```bash
docker-compose run local bash
root@d8fd2d83eb93:/code#
```

And then, run the job with:

`spark-submit job.py`

Which will estimate pi by randomly sampling a billion random points. On my 2018 Macbook Pro, this takes about 150 seconds on 4 cores, though this might vary a bit depending on how Docker is configured on your machine. In a second, we'll deploy a cluster to EC2 that can do this in ~3 seconds, on hardware that costs ~$4/hour.

To speed this up during development, we can reduce the sample count by passing a value for the `n` CLI argument. Just put two dashes `--` after the regular `spark-submit` command, and then any further arguments or flags will get forwarded to the Python program. Eg, to run just 1000 samples:

`spark-submit job.py -- 1000`

Also, since the `/code` directory is mounted as a volume, any changes we make to the source code will immediately appear in the container. Eg, let's add a CLI flag that makes it possible to specify the number of partitions in the RDD, which will come in handy on the production cluster:

```python
@click.command()
@click.argument('n', type=int, default=1e9)
@click.option('--partitions', type=int, default=10)
def main(n, partitions):
    """Estimate pi by sampling a billion random points.
    """
    sc = SparkContext.getOrCreate()

    count = sc.parallelize(range(n), partitions).filter(inside).count()
    pi = 4 * count / n

    print(pi)
```
