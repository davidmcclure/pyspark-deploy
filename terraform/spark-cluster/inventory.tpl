
[master]
${master_ip}

[workers]
${worker_ips}

[spark:children]
master
workers

[spark:vars]
tf_master_private_dns=${master_private_dns}
tf_driver_memory=${driver_memory}
tf_driver_max_result_size=${driver_max_result_size}
tf_executor_memory=${executor_memory}
