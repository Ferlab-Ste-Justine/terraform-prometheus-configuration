# About

Templating module that returns prometheus recording rules and alerts for various exporters and pushed metrics that we use.

The following are currently supported:
- Blackbox Exporter
- Etcd Exporter
- Kubernetes Exporter
- Node Exporter
- Patroni Exporter
- Vault Exporter
- Starrocks Exporter
- Prometheus Exporter
- Terracd Jobs (pushed metrics)
- Minio Exporter (note: support for minio will be phased out in the future)
- Heartbeats (daily alert meant to confirm that the prometheus alerting stack is still operational)

Initially, those templates lived here: https://github.com/Ferlab-Ste-Justine/terraform-etcd-prometheus-configuration/tree/v0.17.0/templates

However, with the need to support some public cloud platforms, we've isolated the templates in a separate terraform module to limit template repetition across environments.

# Inputs

- **prometheus_exporter_job**: Parameters for prometheus exporter alerts.
  - **enabled**: Flag to enable/disabled prometheus alerts.
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
- **node_exporter_jobs**: List of node exporter jobs to generate boilerplate for. Each entry should take the following keys:
  - **tag**: Tag for the node exporter job. Is should consist of words separated by dashes. The job is expected to be called `<tag>-node-exporter`
  - **memory_usage_threshold**: Maximum memory usage as a percentage (ex: 90). An alert will be triggered if this threshold is crossed for 15 minutes of more.
  - **cpu_usage_threshold**: Maximum cpu usage as a percentage (ex: 90). An alert will be triggered if this threshold is crossed for 15 minutes of more.
  - **expected_disks_count**: Expected number of disks (ex: 2). An alert will be triggered if the number of disks doesn't match. Can be set to -1 to disable the alert.
  - **disk_space_usage_threshold**: Maximum disk space usage as a percentage (ex: 90). An alert will be triggered if this threshold is crossed for 15 minutes of more.
  - **disk_io_usage_threshold**: Maximum disk io usage as a percentage (ex: 90). An alert will be triggered if this threshold is crossed for 15 minutes of more.
  - **disk_count_selector**: Selector to narrow which disks should be counted for the **expected_disks_count** alert.
    - **include_path_regex**: Include only disk whose hardware path matches the regex
    - **exclude_path_regex**: Exclude disks whose hardware path matches the regex
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
- **blackbox_exporter_jobs**: List of blackbox tcp/http exporter jobs to generate boilerplate for. Each entry should take the following keys:
  - **tag**: Tag for the blackbox exporter job. Is should consist of words separated by dashes. The job is expected to be called `<tag>-blackbox-exporter`
  - **unavailability_tolerance**: Duration the service can be unavailable before an alert triggers. The format of the duration is a string formated as prometheus expects in the **for** field of alert rules.
  - **max_acceptable_latency**: Duration in seconds indicating the maximum acceptable response time for the service. If the service continuously takes longer than this to respond for an interval of time longer than **unavailability_tolerance**, a slow service alert will be triggered.
  - **cert_renewal_window**: Delay in days indicating the expected renewal window for the tls certificate provided by the service. If the certificate the service provides expires within a delay shorter than this window, an alert will be triggered to indicate the certificate wasn't renewed properly.
  - **has_tls**: Boolean indicating whether the service expects a tls connection. If false, alerts for the cert renewal window and tls version will not be set.
  - **expect_recent_tls**: Boolean indicating whether the service is expected to use tls version 1.3. If set to true and the service uses a version of tls older than 1.3, an alert will be triggered.
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
- **terracd_jobs**: List of terracd jobs to generate boilerplate for. Each entry should take the following keys:
  - **tag**: Tag for the terracd job. It should correspond to the job name.
  - **run_interval_threshold**: Interval threshold after which an alert will be triggered if a command did not run. Used to diagnose a non-running pipeline.
  - **apply_interval_threshold**: Interval threshold after which an alert will be triggered if an **apply** command did not run. Used to detect a pipeline that was left in **plan** and never put back on **apply**.
  - **failure_time_frame**: Interval of time where a past failure result will be a candidate to cause an alert. Failing retries will keep the alert in a triggering state while putting the pipeline on hold will allow the alert to phase out (up until **run_interval_threshold** time occure since the last pipeline ran)
  - **provider_use_time_frame**: Interval of time where the terraform providers are considered to be recently used. For this to work, the **metrics** variable in terracd must be in place with **include_providers** set to `true` and **pushgateway** configured.
  - **unit**: Base time unit to use (**minute** or **hour**) that will affect how the time units are interpreted and how the rules are processed
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
  - **legacy_names**: Whether to use legacy metric names from terracd version **0.14.0** or earlier.
- **kubernetes_exporter_jobs**: List of kubernetes exporter jobs to generate boilerplate for. Each entry should take the following key:
  - **tag**: Tag for the kubernetes cluster job. It should correspond to the cluster name.
  - **volume_usage_threshold**: Maximum PVC usage as a percentage (ex: 85) before a `PersistentVolumeAlmostFull` alert triggers. Defaults to 85.
  - **expected_services**: List of expected deployments that should have a certain number of long running instances. Each entry should have the following keys:
    - **namespace**: Namespace where the service is expected to run
    - **name**: Name of the service. It should match the k8 deployment name.
    - **expected_min_count**: Minimum expected number of instances that should be running.
    - **expected_start_delay**: Expected delay before an instance is started. Running instances that have been around for less than that delay won't be considered running.
    - **alert_labels**: Extra labels to add to alerts triggered for the service.
- **minio_exporter_jobs**: List of minio exporter jobs to generate boilerplate for. Each entry should take the following key:
  - **tag**: Tag for the minio cluster job. It should correspond to the cluster name.
- **etcd_exporter_jobs**: List of etcd exporter jobs to generate boilerplate for. Each entry should take the following keys:
  - **tag**: Tag for the etcd exporter job. Is should consist of words separated by dashes. The job is expected to be called `<tag>-etcd-exporter`
  - **members_count**: Expected number of etcd members associated with the job
  - **max_learn_time**: Max expected time for an etcd learner to catchup. 
  - **max_db_size**: Maximum expected data size (note that etcd has its own limit if 8GiB)
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
- **patroni_exporter_jobs**: List of patroni exporter jobs to generate boilerplate for. Each entry should take the following keys:
  - **tag**: Tag for the patroni exporter job. Is should consist of words separated by dashes. The job is expected to be called `<tag>-patroni-exporter`
  - **members_count**: Expected number of patroni members associated with the job
  - **synchronous_replication**: Whether the patroni cluster is set with synchronous replication or not. If true, an alert will be triggered if a sync standby node is not detected.
  - **patroni_version**: Expected patroni version in semver notation (ex: `4.0.4`). Alternatively, a single major version number can be passed (ex: `4`) if you don't care about fine version granularity.
  - **postgres_version**: Expected postgres version in semver notation (ex: `14.0.15`). Alternatively, a single major version number can be passed (ex: `14`) if you don't care about fine version granularity.
  - **max_wal_divergence**: Max expected WAL divergence between the most up to date and least up to date replica in megabytes. An alert will be triggered if the WAL difference between replicas is greater than this threshold.
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
- **vault_exporter_jobs**: List of Vault telemetry jobs to generate boilerplate for. Each entry should take the following keys:
  - **tag**: Tag for the Vault telemetry job. It should correspond to the job name.
  - **expected_unsealed_count**: Expected number of unsealed Vault nodes in the cluster. An alert will be triggered if the number of unsealed nodes drops below this value.
  - **alert_labels**: Map of string keys and values corresponding to labels to add to all the jobs' alerts.
- **heartbeat**: Parameters for a heartbeat alert to get a daily confirmation that alerting works end-to-end. It takes the following keys:
  - **enabled**: Boolean flag to enable or disabled daily heartbeat alerts
  - **hour**: Hour (0 to 23, UTC time) when the heartbeat alert should happen
  - **minute**: Minute of the hour (0 to 59) when the heartbeat alert should happen
  - **alert_labels**: Map of string keys and values corresponding to labels to add to the alert
- **starrocks_exporter_jobs**: List of starrocks exporter jobs to generate boilerplate for. Each entry should take the following keys:
  - **be**: Parameters for the backend servers alerts
    - **count**: Expected number of backend nodes
    - **cpu_usage_threshold**: Acceptable sustained percentage (ex: 95) utilisation for the cpu. If omitted, rules and alerts for cpu usage won't be present.
    - **cpus_per_node**: Cpu cores per backend node. If omitted, rules and alerts for cpu usage won't be present.
    - **memory_usage_threshold**: Acceptable sustained percentage (ex: 90) utilisation for the memory. If omitted, rules and alerts for memory usage won't be present.
    - **memory_per_node**: Memory, in bytes, per backend node. If omitted, rules and alerts for memory usage won't be present.
    - **disk_space_usage_threshold**: Acceptable sustained percentage (ex: 90) of space utilisation for the disks. If omitted, rules and alerts for disk space usage won't be present.
    - **disk_io_usage_threshold**: Acceptable sustained percentage (ex: 95) of io utilisation for the disks. If omitted, rules and alerts for disk io usage won't be present.
  - **fe**: Parameters for the frontend servers alerts
    - **count**: Expected number of frontend nodes
    - **heap_usage_threshold**: Acceptable sustained percentage (ex: 90) of heap utilisation for the jvm. If omitted, rules and alerts for jvm heap usage won't be present.
    - **query_error_rate_threshold**: Unacceptable number of frontend query errors per second. For a useful alert that is not noisy on an healthy cluster, a low non-zero value should be used.
    - **compaction_score_threshold**: Threshold for the number of unmerged data versions. A value above 100 is considered high and errors will be reported at 1000. Defaults to 100.
    - **meta_log_count_threshold**: Threshold for the number of unmerged logs to disk. Normally, starrocks triggers a checkpoint to flush once the number reaches 50 000 and values well above that are considered high. Defaults to 100 000.
    - **p95_query_latency_threshold**: Unacceptable latency of frontend queries at the 0.95 quantile (ie, roughly the lower end of the 5% slowest query). If omitted, an alert won't be triggered for it.
    - **txn_publish_delay_threshold**: Unacceptable observed maximum latency to publish a commited transaction (which makes it visible). If omitted, an alert won't be triggered for it.

# Output

- **rules**: An array of entries with the values **name** and **content**. The content is a string containing prometheus recording rules and alerts and **name** is its name based on tag value with some context added to it.

# Note About Matching Jobs With Tags

The tags for different exporters match the jobs as follow:
- **node_exporter_jobs**: Metrics **job** label is expected to have the value `<tag>-node-exporter`
- **blackbox_exporter_jobs**: Metrics **job** label is expected to have the value `<tag>-blackbox-exporter`
- **kubernetes_exporter_jobs**: Metrics **cluster** label is expected to have the value `<tag>`
- **minio_exporter_jobs**: Metrics **cluster** label is expected to have the value `<tag>`
- **etcd_exporter_jobs**: Metrics **job** label is expected to have the value `<tag>-etcd-exporter`
- **patroni_exporter_jobs**: Metrics **job** label is expected to have the value `<tag>-patroni-exporter`
- **vault_exporter_jobs**: Metrics **job** label is expected to have the value `<tag>-vault-exporter`
- **terracd_jobs**: Metrics **job** label is expected to have the value `<tag>`
