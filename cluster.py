#!/usr/bin/env python

import click
import subprocess
import json

from typing import Optional
from pydantic import BaseModel

from ansible import constants as C
from ansible.cli import CLI
from ansible.parsing.yaml.objects import AnsibleVaultEncryptedUnicode
from ansible.parsing.dataloader import DataLoader


# TODO: Parametrize? Scan parent dirs recursively?
config_path = '../cluster.yml'


class ClusterConfig(BaseModel):

    aws_region = 'us-east-1'
    aws_availability_zone = 'us-east-1a'
    aws_vpc_id: str
    aws_subnet_id: str
    aws_ami: str
    master_instance_type = 'c5.xlarge'
    worker_instance_type = 'm5a.8xlarge'
    worker_count = 1
    worker_spot_price = 0.8
    master_root_vol_size = 10
    worker_root_vol_size = 100
    public_key_path: str

    docker_image: str
    aws_access_key_id: str
    aws_secret_access_key: str
    master_docker_runtime = ''
    worker_docker_runtime = ''
    driver_memory = '5g'
    driver_max_result_size = '10g'
    executor_memory = '100g'

    class Config:

        extra = 'forbid'

        terraform_keys = (
            'aws_region',
            'aws_availability_zone',
            'aws_vpc_id',
            'aws_subnet_id',
            'aws_ami',
            'master_instance_type',
            'worker_instance_type',
            'worker_count',
            'worker_spot_price',
            'master_root_vol_size',
            'worker_root_vol_size',
            'public_key_path',
        )

        ansible_keys = (
            'docker_image',
            'aws_access_key_id',
            'aws_secret_access_key',
            'master_docker_runtime',
            'worker_docker_runtime',
            'driver_memory',
            'driver_max_result_size',
            'executor_memory',
        )

    def terraform_vars(self) -> dict:
        """Build dict of TF vars.
        """
        return {
            key: getattr(self, key)
            for key in self.Config.terraform_keys
        }

    def write_terraform_vars(self):
        """Render out TF variable file.
        """
        with open('terraform.tfvars.json', 'w') as fh:
            json.dump(self.terraform_vars(), fh, indent=2)

    def ansible_vars_json(self) -> str:
        """Build prefixed Ansible vars.
        """
        return json.dumps({
            f'spark_{key}': getattr(self, key)
            for key in self.Config.ansible_keys
        })


def read_vault_yaml(path: str) -> dict:
    """Read YAML with vault-encrypted values.
    """
    loader = DataLoader()

    vault_secrets = CLI.setup_vault_secrets(
        loader=loader,
        vault_ids=C.DEFAULT_VAULT_IDENTITY_LIST,
    )

    loader.set_vault_secrets(vault_secrets)

    return loader.load_from_file(path)


def read_config(path: str, profile: Optional[str] = None) -> ClusterConfig:
    """Read YAML config, apply profile.
    """
    config = read_vault_yaml(path)

    profiles = config.pop('profiles')

    # Merge profile settings.
    profile_config = profiles[profile] if profile else {}
    config = {**config, **profile_config}

    # Cast decrypted unicode -> raw str.
    config = {
        key: str(val) if type(val) is AnsibleVaultEncryptedUnicode else val
        for key, val in config.items()
    }

    return ClusterConfig(**config)


def read_master_ip():
    """Read the master IP out of the TF state.
    """
    with open('terraform.tfstate') as fh:
        return json.load(fh)['outputs']['master_ip']['value']


@click.group()
def cli():
    pass


@cli.command()
@click.argument('profile', required=False)
def create(profile: Optional[str]):
    """Start a cluster.
    """
    config = read_config(config_path, profile)

    config.write_terraform_vars()

    subprocess.run(['terraform', 'apply'])

    # Pass the Ansible config as a CLI arg, to avoid writing decrypted secrets
    # to the local filesystem.
    subprocess.run([
        'ansible-playbook',
        '-e', config.ansible_vars_json(),
        'deploy.yml',
    ])


@cli.command()
def destroy():
    """Destroy the cluster.
    """
    subprocess.run(['terraform', 'destroy'])


@cli.command()
def login():
    """SSH into the master node.
    """
    subprocess.run(['ssh', f'ubuntu@{read_master_ip()}'])


@cli.command()
def web_admin():
    """Open the Spark web UI.
    """
    subprocess.run(['open', f'http://{read_master_ip()}:8080'])


if __name__ == '__main__':
    cli()
