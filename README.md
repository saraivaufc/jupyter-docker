# jupyter-docker

## Services

* Jupyter notebook
* Tensorflow GPU
* Apache Spark GPU

Spark Master UI	http://localhost:4080
Spark Jobs	http://localhost:4040
Jupyter notebook	http://localhost:8899

## Test Tensorflow GPU


```shell
docker run --rm -it --gpus=all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark
```

```python
import tensorflow as tf
print(tf.config.list_physical_devices('GPU'))
```

## Test Apache Spark GPU

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Test Spark GPU") \
    .config("spark.plugins", "com.nvidia.spark.SQLPlugin") \
    .config("spark.rapids.sql.enabled", "true") \
    .config("spark.rapids.sql.explain", "ALL") \
    .config("spark.executor.resource.gpu.amount", "1") \
    .config("spark.task.resource.gpu.amount", "0.5") \
    .config("spark.rapids.memory.pinnedPool.size", "2G") \
    .getOrCreate()

df = spark.range(0, 10000000)
df2 = df.select((df.id * 2).alias("value"))

df2.show()
```