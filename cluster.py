#!/usr/bin/env poetry run python

import click
import subprocess

from typing import Optional

from pyspark_deploy import config_path, read_config, read_master_ip


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