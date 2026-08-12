output "rules" {
  description = "List of rules"
  value = concat(
    [for terracd_job in var.terracd_jobs: {
      name    = "${terracd_job.tag}-terracd"
      content = templatefile(
        "${path.module}/templates/terracd.yml.tpl",
        {
          job = {
            tag                      = terracd_job.tag
            run_interval_threshold   = terracd_job.run_interval_threshold
            apply_interval_threshold = terracd_job.apply_interval_threshold
            failure_time_frame       = terracd_job.failure_time_frame
            provider_use_time_frame  = terracd_job.provider_use_time_frame
            unit                     = terracd_job.unit
            time_dividor             = terracd_job.unit == "minute" ? 60 : 3600
            alert_labels             = terracd_job.alert_labels
            command_timestamp_metric = terracd_job.legacy_names ? "terracd_timestamp_seconds" : "terracd_command_timestamp_seconds"
          }
        }
      )
    }],
    [for node_exporter_job in var.node_exporter_jobs: {
      name    = "${node_exporter_job.tag}-node-exporter"
      content = templatefile(
        "${path.module}/templates/node-exporter.yml.tpl",
        {
          job = {
            tag                        = node_exporter_job.tag
            memory_usage_threshold     = node_exporter_job.memory_usage_threshold
            cpu_usage_threshold        = node_exporter_job.cpu_usage_threshold
            expected_disks_count       = node_exporter_job.expected_disks_count
            disk_space_usage_threshold = node_exporter_job.disk_space_usage_threshold
            disk_io_usage_threshold    = node_exporter_job.disk_io_usage_threshold
            disk_count_selector              = {
              include_path_filter = node_exporter_job.disk_count_selector.include_path_regex != null ? "path=~\"${node_exporter_job.disk_count_selector.include_path_regex}\"," : ""
              exclude_path_filter = node_exporter_job.disk_count_selector.exclude_path_regex != null ? "path!~\"${node_exporter_job.disk_count_selector.exclude_path_regex}\"," : ""
            }
            alert_labels               = node_exporter_job.alert_labels
          }
        }
      )
    }],
    [for blackbox_exporter_job in var.blackbox_exporter_jobs: {
      name = "${blackbox_exporter_job.tag}-blackbox-exporter"
      content = templatefile(
        "${path.module}/templates/blackbox-exporter.yml.tpl",
        {
          job = blackbox_exporter_job
        }
      )
    }],
    [for kubernetes_exporter_job in var.kubernetes_exporter_jobs: {
      name = "${kubernetes_exporter_job.tag}-kubernetes-exporter"
      content = templatefile(
        "${path.module}/templates/kubernetes-exporter.yml.tpl",
        {
          job = kubernetes_exporter_job
        }
      )
    }],
    [for minio_exporter_job in var.minio_exporter_jobs: {
      name = "${minio_exporter_job.tag}-minio-exporter"
      content = templatefile(
        "${path.module}/templates/minio-exporter.yml.tpl",
        {
          job = minio_exporter_job
        }
      )
    }],
    [for etcd_exporter_job in var.etcd_exporter_jobs: {
      name = "${etcd_exporter_job.tag}-etcd-exporter"
      content = templatefile(
        "${path.module}/templates/etcd-exporter.yml.tpl",
        {
          job = etcd_exporter_job
        }
      )
    }],
    [for patroni_exporter_job in var.patroni_exporter_jobs: {
      name = "${patroni_exporter_job.tag}-patroni-exporter"
      content = templatefile(
        "${path.module}/templates/patroni-exporter.yml.tpl",
        {
          job = {
            tag                     = patroni_exporter_job.tag
            members_count           = patroni_exporter_job.members_count
            synchronous_replication = patroni_exporter_job.synchronous_replication
            max_wal_divergence      = patroni_exporter_job.max_wal_divergence
            patroni_version         = length(split(".", patroni_exporter_job.patroni_version)) > 1 ? join("", [for idx, val in split(".", patroni_exporter_job.patroni_version): length(val) == 1 && idx != 0 ? "0${val}" : val]) : patroni_exporter_job.patroni_version
            patroni_full_version    = length(split(".", patroni_exporter_job.patroni_version)) > 1
            postgres_version        = length(split(".", patroni_exporter_job.postgres_version)) > 1 ? join("", [for idx, val in split(".", patroni_exporter_job.postgres_version): length(val) == 1 && idx != 0 ? "0${val}" : val]) : patroni_exporter_job.postgres_version
            postgres_full_version   = length(split(".", patroni_exporter_job.postgres_version)) > 1
            alert_labels            = patroni_exporter_job.alert_labels
          }
        }
      )
    }],
    [for vault_exporter_job in var.vault_exporter_jobs: {
      name = "${vault_exporter_job.tag}-vault-exporter"
      content = templatefile(
        "${path.module}/templates/vault-exporter.yml.tpl",
        {
          job = vault_exporter_job
        }
      )
    }],
    [for starrocks_exporter_job in var.starrocks_exporter_jobs: {
      name = "${starrocks_exporter_job.tag}-starrocks-exporter"
      content = templatefile(
        "${path.module}/templates/starrocks-exporter.yml.tpl",
        {
          job = starrocks_exporter_job
        }
      )
    }],
    var.heartbeat.enabled ? [{
      name = "heartbeat"
      content = templatefile(
        "${path.module}/templates/heartbeat.yml.tpl",
        {
          heartbeat = var.heartbeat
        }
      )
    }] : [],
    var.prometheus_exporter_job.enabled ? [{
      name = "prometheus-exporter"
      content = templatefile(
        "${path.module}/templates/prometheus-exporter.yml.tpl",
        {
          alert_labels = var.prometheus_exporter_job.alert_labels
        }
      )
    }] : []
  )
}