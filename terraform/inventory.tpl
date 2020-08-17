
[master]
${master_ip}

[workers]
${worker_ips}

[spark:children]
master
workers

[spark:vars]
tf_master_private_ip=${master_private_ip}
