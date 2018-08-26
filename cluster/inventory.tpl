
[master]
${master_ip}

[workers]
${worker_ips}

[all:vars]
tf_aws_region=${aws_region}
tf_master_private_dns=${master_private_dns}
tf_first_worker_id=${first_worker_id}
tf_driver_memory=${driver_memory}
tf_driver_max_result_size=${driver_max_result_size}
tf_executor_memory=${executor_memory}
