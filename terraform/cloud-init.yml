#cloud-config
write_files:

  - path: /etc/spark/spark-defaults.conf
    encoding: b64
    content: ${base64encode(spark_defaults)}

  - path: /etc/spark/spark-env.sh
    encoding: b64
    content: ${base64encode(spark_env)}