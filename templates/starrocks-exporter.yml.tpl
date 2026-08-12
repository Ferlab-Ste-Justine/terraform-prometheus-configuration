groups:
  - name: ${job.tag}-starrocks-exporter-metrics
    rules:
      #${replace(job.tag, "-", " ")} starrocks frontend members count
      - record: ${replace(job.tag, "-", "_")}_starrocks_fe_members:up:count
        expr: (sum by (job, group) (up{group="fe", job="${job.tag}-starrocks-exporter"})) or (absent(up{group="fe", job="${job.tag}-starrocks-exporter"}) * 0)
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeMembersDown
        expr: ${replace(job.tag, "-", "_")}_starrocks_fe_members:up:count < ${job.fe.count}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Member(s) Down"
          description: "Number of starrocks frontend members detected by job *{{ $labels.job }}* has dropped to *{{ $value }}*"
      #${replace(job.tag, "-", " ")} starrocks backend members count
      - record: ${replace(job.tag, "-", "_")}_starrocks_be_members:up:count
        expr: (sum by (job, group) (up{group="be", job="${job.tag}-starrocks-exporter"})) or (absent(up{group="be", job="${job.tag}-starrocks-exporter"}) * 0)
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeMembersDown
        expr: ${replace(job.tag, "-", "_")}_starrocks_be_members:up:count < ${job.be.count}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Member(s) Down"
          description: "Number of starrocks backend members detected by job *{{ $labels.job }}* has dropped to *{{ $value }}*"
%{ if job.be.cpu_usage_threshold != null && job.be.cpus_per_node != null ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_be_cpu_usage:percentage
        expr: ((process_cpu_usage{job="${job.tag}-starrocks-exporter", group="be"}) / ${job.be.cpus_per_node}) * 100
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeCPUUsageHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_be_cpu_usage:percentage > ${job.be.cpu_usage_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Process(es) High CPU Usage"
          description: "Starrocks backend instance *{{ $labels.instance }}* of job *{{ $labels.job }}* has been running on high CPU for a while. Currently at *{{ $value }}*% usage"
%{ endif ~}
%{ if job.fe.heap_usage_threshold != null ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_fe_heap_usage:percentage
        expr: jvm_heap_size_bytes{job="${job.tag}-starrocks-exporter", group="fe", type="used"} / on(group, job, instance) jvm_heap_size_bytes{job="${job.tag}-starrocks-exporter", group="fe", type="max"}
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeHeapUsageHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_fe_heap_usage:percentage > ${job.fe.heap_usage_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Process(es) High Heap Usage"
          description: "Starrocks frontend instance *{{ $labels.instance }}* of job *{{ $labels.job }}* has been using a high percentage of its maximum jvm heap for a while. Currently at *{{ $value }}*% usage"
%{ endif ~}
%{ if job.be.memory_usage_threshold != null && job.be.memory_per_node != null ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_be_memory_usage:percentage
        expr: (starrocks_be_process_mem_bytes{job="${job.tag}-starrocks-exporter"} / ${job.be.memory_per_node}) * 100
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeMemoryUsageHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_be_memory_usage:percentage > ${job.be.memory_usage_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Process(es) High Memory Usage"
          description: "Starrocks backend instance *{{ $labels.instance }}* of job *{{ $labels.job }}* has been using a high percentage of its maximum memory for a while. Currently at *{{ $value }}*% usage"
%{ endif ~}
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeDiskDown
        expr: count(starrocks_be_disks_state{job="${job.tag}-starrocks-exporter", group="be"}  == 0) by (job, instance, path)
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Disk Down"
          description: "Disk at path *{{ $labels.path }}* of starrocks backend instance *{{ $labels.instance }}* of job *{{ $labels.job }}* is down"
%{ if job.be.disk_space_usage_threshold != null ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_be_disk_space_usage:percentage
        expr: ((starrocks_be_disks_total_capacity{job="${job.tag}-starrocks-exporter", group="be"} - starrocks_be_disks_avail_capacity{job="${job.tag}-starrocks-exporter", group="be"}) / starrocks_be_disks_total_capacity{job="${job.tag}-starrocks-exporter", group="be"}) * 100
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeDiskSpaceUsageHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_be_disk_space_usage:percentage > ${job.be.disk_space_usage_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Disk Space Usage High"
          description: "Disk at path *{{ $labels.path }}* of starrocks backend instance *{{ $labels.instance }}* of job *{{ $labels.job }}* is using a high percentage of it's maximum space capacity. It is at *{{ $value }}*% usage."
%{ endif ~}
%{ if job.be.disk_io_usage_threshold != null ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_be_disk_io_usage:percentage
        expr: (rate(starrocks_be_disk_io_time_ms{job="${job.tag}-starrocks-exporter", group="be"}[5m]) / 1000) * 100
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeDiskIoUsageHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_be_disk_io_usage:percentage > ${job.be.disk_io_usage_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Disk Io Usage High"
          description: "Disk with device name *{{ $labels.device }}* of starrocks backend instance *{{ $labels.instance }}* of job *{{ $labels.job }}* is using a high percentage of it's maximum io capacity. It is at *{{ $value }}*% usage."
%{ endif ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_fe_query_error_rate:per_second
        expr: sum by (job, group) (rate(starrocks_fe_query_err{job="${job.tag}-starrocks-exporter", group="fe"}[5m]))
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeQueriesFailingALot
        expr: ${replace(job.tag, "-", "_")}:starrocks_fe_query_error_rate:per_second > ${job.fe.query_error_rate_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Queries Error Rate Is High"
          description: "Frontend queries on starrocks cluster of job *{{ $labels.job }}* are failing at a rate of *{{ $value }}* queries per second which is above the designated threshold."
      - record: ${replace(job.tag, "-", "_")}:starrocks_be_schema_change_failure_rate:per_second_recent
        expr: sum by (job, group) (irate(starrocks_be_engine_requests_total{job="${job.tag}-starrocks-exporter", group="be", status="failed", type="schema_change"}[5m]))
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeSchemaChangeFailure
        expr: ${replace(job.tag, "-", "_")}:starrocks_be_schema_change_failure_rate:per_second_recent > 0
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Schema Change Failure Detected"
          description: "Starrocks schema change failure occured in job *{{ $labels.job }}*. Detection of this occurence is based on the last two samples collected."
      - record: ${replace(job.tag, "-", "_")}:starrocks_be_clone_failure_rate:per_second_recent
        expr: sum by (job, group) (irate(starrocks_be_engine_requests_total{job="${job.tag}-starrocks-exporter", group="be", status="failed", type="clone"}[5m]))
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksBeCloneFailure
        expr: ${replace(job.tag, "-", "_")}:starrocks_be_clone_failure_rate:per_second_recent > 0
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Be Clone Failure Detected"
          description: "Starrocks clone failure occured in job *{{ $labels.job }}*. Detection of this occurence is based on the last two samples collected."
      - record: ${replace(job.tag, "-", "_")}:starrocks_fe_max_tablet_compaction_score:max
        expr: max(starrocks_fe_max_tablet_compaction_score{job="${job.tag}-starrocks-exporter", group="fe", is_leader="true"}) by (job, group, is_leader)
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeCompactionScoreTooHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_fe_max_tablet_compaction_score:max > ${job.fe.compaction_score_threshold}
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Max Tablet Compaction Score Too High"
          description: "Starrocks max table compaction score for job *{{ $labels.job }}* has reached *{{ $value }}*. Starrocks will trigger "Too many versions" errors at 1000 if compaction cannot keep up with data ingestion."
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeMetaLogCountTooHigh
        expr: starrocks_fe_meta_log_count{job="${job.tag}-starrocks-exporter", group="fe"} > ${job.fe.meta_log_count_threshold}
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Meta Log Count Too High"
          description: "Meta log count of instance *{{ $labels.instance }}* for starrocks job *{{ $labels.job }}* has reached *{{ $value }}* which is high. This likely indicates a checkpoint failure."
%{ if job.fe.p95_query_latency_threshold != null ~}
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeQueryLatencyTooHigh
        expr: starrocks_fe_query_latency_ms{job="${job.tag}-starrocks-exporter", group="fe", quantile="0.95"} > ${job.fe.p95_query_latency_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe 0.95 Quantile Query Latency Too High"
          description: "0.95 quantile query latency of instance *{{ $labels.instance }}* for starrocks job *{{ $labels.job }}* has been above the set threshold for some time. It is currently at *{{ $value }}*ms."
%{ endif ~}
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeQueriesTimingOut
        expr: rate(starrocks_fe_meta_log_count{job="${job.tag}-starrocks-exporter", group="fe"}[5m]) > 0
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Queries Are Timing Out"
          description: "A portion of incoming queries on frontend instance *{{ $labels.instance }}* for starrocks job *{{ $labels.job }}* have been timing out for some time."
%{ if job.fe.txn_publish_delay_threshold != null ~}
      - record: ${replace(job.tag, "-", "_")}:starrocks_fe_leader_txn_max_committed_pending_publish:ms
        expr: starrocks_fe_txn_max_committed_pending_publish{job="${job.tag}-starrocks-exporter", is_leader="true"}
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}StarrocksFeTxnPublishDelayTooHigh
        expr: ${replace(job.tag, "-", "_")}:starrocks_fe_leader_txn_max_committed_pending_publish:ms > ${job.fe.txn_publish_delay_threshold}
        for: 15m
%{ if length(job.alert_labels) > 0 ~}
        labels:
%{ for key, val in job.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "${title(replace(job.tag, "-", " "))} Starrocks Fe Commited Transactions Publish Delay Too Long"
          description: "Longest transaction publish delays on database *{{ $labels.db }}* for starrocks job *{{ $labels.job }}* have been too long for some time. Longest waiting transaction to publish is currently at *{{ $value }}*ms."
%{ endif ~}