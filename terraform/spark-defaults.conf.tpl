
spark.master spark://${master_private_ip}:7077
spark.driver.memory ${driver_memory}
spark.executor.memory ${executor_memory}
spark.driver.maxResultSize ${max_driver_result_size}
spark.task.maxFailures ${max_task_failures}
spark.hadoop.fs.s3a.connection.maximum ${max_s3_connections}
spark.jars.packages ${packages}

spark.local.dir /data/spark
spark.driver.extraJavaOptions -Dderby.system.home=/data/derby
spark.sql.warehouse.dir /data/spark-warehouse
spark.hadoop.hadoop.tmp.dir /data/hadoop
spark.sql.files.ignoreCorruptFiles true
spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version 2
spark.sql.parquet.enableVectorizedReader false