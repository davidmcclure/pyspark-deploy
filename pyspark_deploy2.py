from pydantic import BaseModel
from pathlib import Path


class ClusterConfig(BaseModel):
    ecr_server: str
    ecr_repo: str
    aws_access_key_id: str
    aws_secret_access_key: str
    wandb_api_key: str
    aws_vpc_id: str
    aws_subnet_id: str
    aws_region: str = 'us-east-1'
    aws_ami: str = 'ami-04eb5b2f5ef92e8b8'
    public_key_path: str = Path.home() / '.ssh/spark.pub'
    root_vol_size: int = 100
    master_instance_type: str = 'c5.xlarge'
    driver_memory: str = '4g'
    worker_instance_type: str = 'c5.xlarge'
    executor_memory: str = '4g'
    spot_worker_count: int = 0
    on_demand_worker_count: int = 0
    gpu_workers: bool = False
    data_dir: str = '/data'
    max_driver_result_size: str = '10g'
    max_task_failures: int = 20
    spark_packages: list[str] = ('org.apache.spark:spark-hadoop-cloud_2.13:3.2.1',)