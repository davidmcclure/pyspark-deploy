#!/usr/bin/env python

import subprocess

from cluster import read_master_ip


if __name__ == '__main__':
    subprocess.run(['ssh', f'ubuntu@{read_master_ip()}'])
