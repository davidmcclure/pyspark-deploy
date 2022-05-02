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


console = Console()


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

    # TODO: Move into submit?
    @property
    def create_url(self) -> str:
        return f'{self.api_url}/v1/submissions/create'

    def ping(self) -> bool:
        try:
            requests.get(self.api_url)
            return True
        except:
            return False

    @property
    def ready(self):
        return self.ping()

    def open_webui(self):
        webbrowser.open(f'http://{self.master_dns}:8080')

    # TODO: app_args, spark_properties, env
    def submit(self, path: str) -> str:
        res = requests.post(self.create_url, json={
            'appResource': f'file:{path}',
            'appArgs': [path],
            'sparkProperties': {
                'spark.app.name': 'os-corpus'
            },
            'clientSparkVersion': '3.2.1',
            'mainClass': 'org.apache.spark.deploy.SparkSubmit',
            'environmentVariables': {
                'SPARK_ENV_LOADED': '1'
            },
            'action': 'CreateSubmissionRequest'
        })

        if res.status_code != 200:
            raise RuntimeError(res.text)

        submission = Submission(
            api_url=self.submissions_url,
            submission_id=res.json()['submissionId'],
        )

        # TODO: Log URL to app UI.
        with console.status('Waiting for job to finish...'):
            while True:
                status = submission.status()
                if status == 'FAILED':
                    raise RuntimeError('Job failed.')
                elif status == 'FINISHED':
                    break
                else:
                    time.sleep(3)

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

    def finished(self) -> bool:
        return self.status() == 'FINISHED'


# TODO: state_path
# class Cluster:

#     def ping_api(self) -> bool:
#         """Ping the job submission API. When this is online, the cluster is up
#         and ready for submissions.
#         """
#         try:
#             requests.get(f'http://{self.master_dns}:6066')
#             return True
#         except:
#             return False

#     @property
#     def ready(self):
#         return self.ping_api()
    
#     # TODO: config object
#     def create(self):
#         """Create a cluster with a given configuration. 
#         """
#         with console.status('Creating cluster...'):
#             subprocess.run(
#                 ['terraform', 'apply', '-auto-approve'],
#                 capture_output=True,
#             )

#         with console.status('Waiting for API...'):
#             for elapsed in wait_for(self.ping_api):
#                 print(elapsed)

#     def destroy(self):
#         with console.status('Destroying cluster...'):
#             subprocess.run(
#                 ['terraform', 'destroy', '-auto-approve'],
#                 capture_output=True,
#             )

#     # TODO: Does this work with s3 state / does it matter?
#     def read_tfstate(self) -> dict:
#         with smart_open.open('terraform.tfstate') as fh:
#             return json.load(fh)

#     # TODO: Raise exception if absent.
#     @property
#     def master_dns(self):
#         state = self.read_tfstate()
#         if master_dns := state['outputs'].get('master_dns'):
#             return master_dns['value']

#     def submit(
#         self,
#         path: str,
#         app_args: Optional[list[str]] = None,
#         spark_properties: Optional[dict] = None,
#     ):
#         return requests.post(f'http://{self.master_dns}:6066/v1/submissions/create', json={
#             "appResource": f"file:{path}",
#             "appArgs": [path],
#             "sparkProperties": {
#                 "spark.app.name": "os-corpus"
#             },
#             "clientSparkVersion": "3.2.1",
#             "mainClass": "org.apache.spark.deploy.SparkSubmit",
#             "environmentVariables": {
#                 "SPARK_ENV_LOADED": "1"
#             },
#             "action": "CreateSubmissionRequest"
#         })


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