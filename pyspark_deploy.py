import subprocess
import json
import smart_open
import time
import requests
import addict
import webbrowser

from datetime import datetime
from pathlib import Path
from typing import Callable, Optional
from dataclasses import dataclass
from rich.console import Console
from pydantic import BaseModel


console = Console()


class ClusterConfig(BaseModel):
    ecr_server: str
    ecr_repo: str
    aws_vpc_id: str
    aws_subnet_id: str
    aws_access_key_id: str
    aws_secret_access_key: str
    wandb_api_key: str
    aws_region: str = 'us-east-1'
    aws_ami: str = 'ami-04eb5b2f5ef92e8b8'
    public_key_path: str = '~/.ssh/spark.pub'
    root_vol_size: int = 100
    master_instance_type: str = 'c5.xlarge'
    driver_memory: str = '4g'
    worker_instance_type: str = 'c5.xlarge'
    executor_memory: str = '4g'
    spot_worker_count: int = 0
    on_demand_worker_count: int = 0
    gpu_workers: bool = False
    data_dir: str = '/data'
    max_driver_result_size: str = "1g"
    max_task_failures: int = 20
    spark_packages: list[str] = (
        'org.apache.spark:spark-hadoop-cloud_2.13:3.2.1',
    )


# TODO: Just block until done, don't return a generator?
def wait_for(check: Callable, interval: int = 3):
    t1 = datetime.now()
    while True:
        if check():
            return
        else:
            yield datetime.now() - t1
            time.sleep(interval)


@dataclass
class ClusterState:

    state_path: str = 'terraform.tfstate'

    # TODO: Pass config
    def create(self):
        with console.status('Creating cluster...'):
            subprocess.run(
                ['terraform', 'apply', '-auto-approve', '-state', self.state_path],
                capture_output=True,
            )

        cluster = self.get_cluster()

        # TODO: Log the elapsed time.
        with console.status('Waiting for API...'):
            for elapsed in wait_for(lambda: cluster.ready):
                pass

        return cluster

    def destroy(self):
        with console.status('Destroying cluster...'):
            subprocess.run(
                ['terraform', 'destroy', '-auto-approve', '-state', self.state_path],
                capture_output=True,
            )

    def read_tfstate(self) -> Optional[dict]:
        path = Path(self.state_path)
        if path.exists():
            return json.load(path.open())

    def read_master_dns(self) -> Optional[str]:
        if state := self.read_tfstate():
            return addict.Dict(state).outputs.master_dns.value or None

    def get_cluster(self):
        if master_dns := self.read_master_dns():
            return Cluster(master_dns)
        else:
            raise Exception('Cluster is down. Call create().')


@dataclass
class Cluster:

    master_dns: str

    @property
    def api_url(self) -> str:
        return f'http://{self.master_dns}:6066'

    @property
    def submissions_url(self) -> str:
        return f'{self.api_url}/v1/submissions'

    def ping(self) -> bool:
        try:
            requests.get(self.api_url)
            return True
        except:
            return False

    @property
    def ready(self):
        return self.ping()

    # TODO: Login too?
    def open_webui(self):
        webbrowser.open(f'http://{self.master_dns}:8080')

    # TODO: app_args, spark_properties, env
    def submit(
        self,
        path: str,
        *,
        python_args: Optional[list[str]] = None,
        spark_properties: Optional[dict] = None,
        env_vars: Optional[dict] = None,
    ) -> dict:
        """Submit a Python file and block until the job finishes.
        """
        url = f'{self.submissions_url}/create'

        res = requests.post(f'{self.submissions_url}/create', json={
            'action': 'CreateSubmissionRequest',
            'mainClass': 'org.apache.spark.deploy.SparkSubmit',
            'clientSparkVersion': '3.2.1',
            'appResource': f'file:{path}',
            'appArgs': [path, '--', *(python_args or [])],
            'sparkProperties': {
                'spark.app.name': 'pyspark-deploy',
                **(spark_properties or {}),
            },
            'environmentVariables': {
                'SPARK_ENV_LOADED': '1',
                **(env_vars or {}),
            },
        })

        if res.status_code != 200:
            raise RuntimeError(res.text)

        submission = Submission(
            api_url=self.submissions_url,
            submission_id=res.json()['submissionId'],
        )

        # TODO: Log URL to app UI.
        with console.status('Running job...'):
            while True:
                status = submission.status()
                if status == 'RUNNING':
                    time.sleep(3)
                elif status == 'FINISHED':
                    break
                else:
                    print(submission.status_json())
                    raise Exception('Job failed.')

        return submission.status_json()


# TODO: Build link to webui for app?
@dataclass
class Submission:

    api_url: str
    submission_id: str

    def status_json(self) -> str:
        url = f'{self.api_url}/status/{self.submission_id}'
        res = requests.get(url)
        return res.json()

    def status(self) -> str:
        return self.status_json()['driverState']


# cluster = Cluster()
# cluster.create(CPUClusterConfig)
# cluster.submit('load_bennington.py', f'--sample {0.1}')
# cluster.submit('load_v1.py', f'--sample {0.1}')
# cluster.create(GPUClusterConfig)
# cluster.submit('parse.py')
# cluster.create(DedupeClusterConfig)
# cluster.submit('dedupe.py')
# cluster.submit('log_metrics.py')

# cluster.submit('parse.py', spark_properties={
#     'spark.executor.cores': 4,
# })

# parse = Job(
#     path='parse.py',
#     cluster_config=GPUClusterConfig,
#     spark_properties={
#         'spark.executor.cores': 4,
#     }
# )

# parse.run()