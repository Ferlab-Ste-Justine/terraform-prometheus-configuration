groups:
  - name: ${job.tag}-minio-metrics
    rules:
      #${replace(job.tag, "-", " ")} minio nodes metrics
      - record: ${replace(job.tag, "-", "_")}_minio:offline_nodes:count
        expr: minio_cluster_nodes_offline_total{cluster="${job.tag}"}
      #${replace(job.tag, "-", " ")} minio drives metrics
      - record: ${replace(job.tag, "-", "_")}_minio:offline_drives:count
        expr: minio_cluster_drive_offline_total{cluster="${job.tag}"} or minio_cluster_disk_offline_total{cluster="${job.tag}"}