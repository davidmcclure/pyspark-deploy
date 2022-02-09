

import json
import yaml
import subprocess
import click

from typing import Optional, List
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
    worker_instance_type = 'm4.4xlarge'
    on_demand_worker_count = 0
    spot_worker_count = 0
    worker_spot_price = 0.4
    master_root_vol_size = 10
    worker_root_vol_size = 100
    public_key_path: str

    docker_image: str
    vault_password_file: Optional[str]
    aws_access_key_id: str
    aws_secret_access_key: str
    master_docker_runtime = ''
    worker_docker_runtime = ''
    driver_memory = '5g'
    driver_max_result_size = '10g'
    executor_memory = '50g'
    extra_packages: List[str] = []
    wandb_api_key: Optional[str]

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
            'on_demand_worker_count',
            'spot_worker_count',
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
            'extra_packages',
            'wandb_api_key',
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
        with open('terraform/config.auto.tfvars.json', 'w') as fh:
            json.dump(self.terraform_vars(), fh, indent=2)

    def ansible_vars(self) -> dict:
        """Build prefixed Ansible vars.
        """
        return {
            f'spark_{key}': getattr(self, key)
            for key in self.Config.ansible_keys
        }

    def write_ansible_vars(self):
        """Render out TF variable file.
        """
        with open('ansible/config.json', 'w') as fh:
            json.dump(self.ansible_vars(), fh, indent=2)


def read_vault_yaml(path: str) -> dict:
    """Read YAML with vault-encrypted values.
    """
    # Read YAML without decrypting.
    raw_clean = open(path).read().replace('!vault', '')
    data = yaml.load(raw_clean, Loader=yaml.FullLoader)

    # Pop out PW file, if provided.
    pw_file = data.get('vault_password_file')
    pw_files = [pw_file] if pw_file else None

    loader = DataLoader()

    vault_secrets = CLI.setup_vault_secrets(
        loader=loader,
        vault_ids=C.DEFAULT_VAULT_IDENTITY_LIST,
        vault_password_files=pw_files,
    )

    loader.set_vault_secrets(vault_secrets)

    # Re-read with decryption.
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
    with open('terraform/terraform.tfstate') as fh:
        return json.load(fh)['outputs']['master_ip']['value']


@click.group()
def cli():
    pass


# TODO: Set the profile separately - config file, or via CLI?
@cli.command()
@click.argument('profile', required=False)
def create(profile: Optional[str]):
    """Start a cluster.
    """
    config = read_config(config_path, profile)

    config.write_terraform_vars()
    config.write_ansible_vars()

    subprocess.run(['terraform', 'apply'], cwd='terraform')
    subprocess.run(['ansible-playbook', 'deploy.yml'], cwd='ansible')


@cli.command()
def destroy():
    """Destroy the cluster.
    """
    subprocess.run(['terraform', 'destroy'], cwd='terraform')


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
