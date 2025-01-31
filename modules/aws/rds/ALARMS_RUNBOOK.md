# Alarms and Actions

- [Alarms and Actions](#alarms-and-actions)
  - [CPU Utilization](#cpu-utilization)
  - [Aurora Capacity Unit (ACU) Utilization](#aurora-capacity-unit-acu-utilization)
  - [Freeable Memory](#freeable-memory)
  - [Read and Write Latency](#read-and-write-latency)
  - [Buffer Cache Hit Ratio](#buffer-cache-hit-ratio)


If the variable `create_cloudwatch_alarm` is true, then several CloudWatch Alarms are created using the
Apres [cloudwatch_alarm](../cloudwatch_alarm/) module. If you have deployed Managed Grafana using the
Apres [grafana_managed](../grafana_managed/) module, the alarms will be automatically populated there.

The next sections outline the alarms and recommended actions.

## CPU Utilization

In both serverless and provisioned scenarios, first look at Performance Insights to determine
which SQL queries are contributing to the high CPU Utilization and require tuning.

In a serverless configuration, if `serverless` is set to true, the CPU Utilization is calculated
as the amount of CPU used divided by the CPU capacity that's available under the maximum ACU value
of the DB cluster. If the alarm persists, look at increasing the number of readers, or increasing the
`serverless_scaling.max_capacity` variable to increase the CPU capacity.

In a provisioned configuration (if `serverless` is set to false), CPU Utlizization is the traditional
utilization of the instance class. If the alarm persists, increase the instance type.

## Aurora Capacity Unit (ACU) Utilization

Only valid for serverless configurations.

ACU is the Aurora Capacity Unit, used since Aurora Servless is not tied to an instance type. See
[Aurora Serverless v2 Capacity](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html#aurora-serverless-v2.how-it-works.capacity)
on what ACU's are, and
[Important Amazon CloudWatch metrics for Aurora Servless v2](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.setting-capacity.html#aurora-serverless-v2.viewing.monitoring)
for metric details.

If this metric approaches 100%, the Aurora cluster has scaled up as far as it can. Either reduce the load by
tuning queries, or increase the maximum size using the `serverless_scaling.max_capacity` variable to
increase the CPU capacity.

## Freeable Memory

The amount of free memory on the instance is too low.

See [Important Amazon CloudWatch metrics for Aurora Servless v2](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.setting-capacity.html#aurora-serverless-v2.viewing.monitoring)
for details.

In a serverless configuration considering inecreasing the `serverless_scaling.max_capacity` variable. In
a provisioned configuration consider increasing the `instance_class` to a larger instance.

## Read and Write Latency

High read or write latency means your queries may be slow, affecting your application. Next steps are highly
dependant on your application, but may include tuning your queries, adding indexes. Alternately look at
scaling up the Aurora cluster:
* If the cluster is serverless, look at increasing `serverless_scaling.max_capacity`
* Investigate changing the `storage_type` to `io-optimized`, which may increase cost.
* If not serverless, look at larger instance classes with more memory and more instance storage.

## Buffer Cache Hit Ratio

This metric measures the percentage of requests that are served by the buffer cache of a DB instance in your DB cluster. This metric gives you an insight into the amount of data that is being served from memory.

A high hit ratio indicates that your DB instance has enough memory available. A low hit ratio indicates that your queries on this DB instance are frequently going to disk. Investigate your workload to see which queries are causing this behavior. Alternately investigate increasing the `serverless_scaling.max_capacity` or increasing the
provisioned `instance_class` to gain more memory.