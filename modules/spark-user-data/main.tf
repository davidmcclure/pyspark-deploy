
locals {
  log4j_properties_b64 = base64encode(file("${path.module}/log4j.properties"))

  spark_bash_b64 = base64encode(file("${path.module}/spark-bash.sh"))

  spark_env_b64 = base64encode(templatefile("${path.module}/spark-env.sh", {
    data_dir              = var.data_dir
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    wandb_api_key         = var.wandb_api_key
  }))

  spark_defaults_b64 = base64encode(templatefile("${path.module}/spark-defaults.conf", {
    driver_memory          = var.driver_memory
    executor_memory        = var.executor_memory
    max_driver_result_size = var.max_driver_result_size
    spark_packages         = var.spark_packages
    data_dir               = var.data_dir
    max_task_failures      = var.max_task_failures
    master_private_ip      = var.master_private_ip
  }))

  start_spark_b64 = base64encode(templatefile("${path.module}/start-spark.sh", {
    ecr_server            = var.ecr_server
    ecr_repo              = var.ecr_repo
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    master_private_ip     = var.master_private_ip
  }))
}

output "rendered" {
  value = templatefile("${path.module}/cloud-config.yaml", {
    log4j_properties_b64 = local.log4j_properties_b64
    spark_bash_b64       = local.spark_bash_b64
    spark_env_b64        = local.spark_env_b64
    spark_defaults_b64   = local.spark_defaults_b64
    start_spark_b64      = local.start_spark_b64
  })
  sensitive = true
}