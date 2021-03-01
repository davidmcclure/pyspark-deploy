
[master]
${master_ip}

[workers]
${worker_ips}

[spark:children]
master
workers

[spark:vars]
master_private_ip=${master_private_ip}
aws_access_key_id=${aws_access_key_id}
aws_secret_access_key=${aws_secret_access_key}
docker_image=${docker_image}