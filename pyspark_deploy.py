import subprocess
import json
import tempfile
import requests
import time

from datetime import datetime as dt
from pydantic import BaseModel
from pathlib import Path
from dataclasses import dataclass
from typing import Optional, Callable
# from loguru import logger
from rich.console import Console


"""
approve / show_output
how to handle env vars / run id
"merge" list / dict config overrides
log links / open browser for webui + job
"""


ROOT_DIR = Path(__file__).parent

console = Console()


class ClusterConfig(BaseModel):
    ecr_server: str
    ecr_repo: str
    aws_access_key_id: str
    aws_secret_access_key: str
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
    spark_packages: list[str] = ('org.apache.spark:spark-hadoop-cloud_2.13:3.2.1',) # noqa


def wait_for(check: Callable, msg: str, interval: int = 3):
    """Call a check function every N sections until it returns true.
    """
    with console.status(msg) as status:
        t1 = dt.now()
        while True:
            if check():
                # TODO: Log total elapsed time.
                return
            else:
                elapsed = dt.now() - t1
                status.update(f'{msg} - {elapsed}')
                time.sleep(interval)


def run_terraform(args: list[str]):
    subprocess.run(['terraform'] + args, cwd=ROOT_DIR)


def setup():
    run_terraform(['init'])


@dataclass
class Cluster:

    state_path: str = 'terraform.tfstate'

    # TODO: Params for auto_approve, show_output
    def create(self, config: ClusterConfig):

        config_file = tempfile.NamedTemporaryFile('w', suffix='.json')
        config_file.write(config.json())
        config_file.seek(0)

        run_terraform([
            'apply',
            f'-state={self.state_path}',
            f'-var-file={config_file.name}',
            '-auto-approve',
        ])

        wait_for(self.ping, 'Waiting for API...')
        # TODO: Log web UI URL.

    def destroy(self):
        run_terraform([
            'destroy',
            f'-state={self.state_path}',
            '-auto-approve',
        ])

    def submit(
        self,
        path: str,
        *,
        python_args: Optional[list[str]] = None,
        spark_properties: Optional[dict] = None,
        env_vars: Optional[dict] = None,
    ):
        """Submit a Python file and block until the job finishes.
        """
        url = f'{self.api_url}/create'

        res = requests.post(url, json={
            'action': 'CreateSubmissionRequest',
            'mainClass': 'org.apache.spark.deploy.SparkSubmit',
            'clientSparkVersion': '3.2.1',
            'appResource': f'file:{path}',
            'sparkProperties': {
                'spark.app.name': 'pyspark-deploy',
                **(spark_properties or {}),
            },
            'environmentVariables': {
                'SPARK_ENV_LOADED': '1',
                **(env_vars or {}),
            },
            'appArgs': [path, '--', *(python_args or [])],
        })

        # Raise errors for malformed requests.
        if res.status_code != 200:
            raise RuntimeError(res.text)

        submission = Submission(
            api_url=self.api_url,
            submission_id=res.json()['submissionId']
        )

        # Block until the job finishes.
        wait_for(submission.check, 'Running job...')

    def read_tfstate(self) -> dict:
        path = Path(self.state_path)

        if path.exists():
            return json.load(path.open())

        raise Exception('No Terraform state. Is the cluster up?')

    @property
    def master_dns(self) -> str:
        state = self.read_tfstate()

        if master_dns := state['outputs'].get('master_dns'):
            return master_dns['value']

        raise Exception('No `master_dns` output. Is the cluster up?')

    @property
    def api_url(self) -> Optional[str]:
        return f'http://{self.master_dns}:6066/v1/submissions'

    def ping(self) -> bool:
        try:
            requests.get(self.api_url, timeout=3)
            return True
        except ConnectionError:
            return False


@dataclass
class Submission:

    api_url: str
    submission_id: str

    def status(self) -> str:
        url = f'{self.api_url}/status/{self.submission_id}'
        return requests.get(url).json()

    def driver_state(self) -> str:
        return self.status()['driverState']

    def check(self) -> bool:
        """Check to see if the job is finished. If it's in a state other than
        RUNNING or FINISHED, raise an exception.
        """
        state = self.driver_state()
        if state == 'FINISHED':
            return True
        elif state == 'RUNNING':
            return False
        else:
            print(self.status())
            raise RuntimeError('Job failed.')
