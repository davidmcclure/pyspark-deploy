
[master]
${master_ip}

[workers]
${on_demand_worker_ips}
${spot_worker_ips}

[spark:children]
master
workers

[spark:vars]
tf_master_private_ip=${master_private_ip}
