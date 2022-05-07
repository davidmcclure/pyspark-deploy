import os

from dotenv import load_dotenv
from pathlib import Path

from pyspark_deploy2 import ClusterConfig as BaseClusterConfig, Cluster


load_dotenv()

cluster = Cluster(Path(__file__).parent / 'terraform.tfstate')


class ClusterConfig(BaseClusterConfig):
    ecr_server = '636774461479.dkr.ecr.us-east-1.amazonaws.com'
    ecr_repo = 'osp-corpus:latest'
    aws_vpc_id = 'vpc-03cfe91905bcc2582'
    aws_subnet_id = 'subnet-0dcfc4d5ca69f6633'
    aws_access_key_id = os.environ['AWS_ACCESS_KEY_ID']
    aws_secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY']
    wandb_api_key = os.environ['WANDB_API_KEY']


class LoadClusterConfig(ClusterConfig):
    spot_worker_count = 2
