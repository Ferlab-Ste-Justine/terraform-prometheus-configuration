groups:
  - name: ${job.tag}-kubernetes-metrics
    rules:
      #${replace(job.tag, "-", " ")} kubernetes pods status metrics
      - record: ${replace(job.tag, "-", "_")}_kubernetes:healthy_pods_ratio_by_namespace:percentage
        expr: 100 * sum by (namespace) (kube_pod_status_phase{phase=~"Running|Succeeded", cluster="${job.tag}"}) / sum by (namespace) (kube_pod_status_phase{cluster="${job.tag}"})
      #${replace(job.tag, "-", " ")} kubernetes containers CPU metrics
      - record: ${replace(job.tag, "-", "_")}_kubernetes:containers_cpu_request_usage:percentage
        expr: 100 * max by (namespace, pod, container) (rate(container_cpu_usage_seconds_total{cluster="${job.tag}"}[5m]) / on (namespace, pod, container) kube_pod_container_resource_requests{resource="cpu", cluster="${job.tag}"})
      - record: ${replace(job.tag, "-", "_")}_kubernetes:containers_cpu_limit_usage:percentage
        expr: 100 * max by (namespace, pod, container) (rate(container_cpu_usage_seconds_total{cluster="${job.tag}"}[5m]) / on (namespace, pod, container) kube_pod_container_resource_limits{resource="cpu", cluster="${job.tag}"})
      - record: ${replace(job.tag, "-", "_")}_kubernetes:container_missing_cpu_request:count
        expr: sum by (namespace, pod, container)(kube_pod_container_info{container!="", cluster="${job.tag}"}) unless sum by (namespace, pod, container)(kube_pod_container_resource_requests{resource="cpu"})
      - record: ${replace(job.tag, "-", "_")}_kubernetes:container_missing_cpu_limit:count
        expr: sum by (namespace, pod, container)(kube_pod_container_info{container!="", cluster="${job.tag}"}) unless sum by (namespace, pod, container)(kube_pod_container_resource_limits{resource="cpu"})
      #${replace(job.tag, "-", " ")} kubernetes containers memory metrics
      - record: ${replace(job.tag, "-", "_")}_kubernetes:containers_memory_request_usage:percentage
        expr: 100 * max by (namespace, pod, container) (container_memory_working_set_bytes{cluster="${job.tag}"} / on (namespace, pod, container) kube_pod_container_resource_requests{resource="memory", cluster="${job.tag}"})
      - record: ${replace(job.tag, "-", "_")}_kubernetes:containers_memory_limit_usage:percentage
        expr: 100 * max by (namespace, pod, container) (container_memory_working_set_bytes{cluster="${job.tag}"} / on (namespace, pod, container) kube_pod_container_resource_limits{resource="memory", cluster="${job.tag}"})
      - record: ${replace(job.tag, "-", "_")}_kubernetes:container_missing_memory_request:count
        expr: sum by (namespace, pod, container)(kube_pod_container_info{container!="", cluster="${job.tag}"}) unless sum by (namespace, pod, container)(kube_pod_container_resource_requests{resource="memory"})
      - record: ${replace(job.tag, "-", "_")}_kubernetes:container_missing_memory_limit:count
        expr: sum by (namespace, pod, container)(kube_pod_container_info{container!="", cluster="${job.tag}"}) unless sum by (namespace, pod, container)(kube_pod_container_resource_limits{resource="memory"})
      #${replace(job.tag, "-", " ")} kubernetes volumes metrics
      - record: ${replace(job.tag, "-", "_")}_kubernetes:volumes_usage:percentage
        expr: 100 * sum(kubelet_volume_stats_used_bytes{cluster="${job.tag}"}) by (namespace, persistentvolumeclaim) / sum(kubelet_volume_stats_capacity_bytes{cluster="${job.tag}"}) by (namespace, persistentvolumeclaim)
%{ for service in job.expected_services ~}
      - record: ${replace(job.tag, "-", "_")}_${replace(service.name, "-", "_")}_running_pods:count
        expr: sum by () (kube_pod_status_phase{phase="Running", pod=~"${service.name}([-][a-z0-9]+([-][a-z0-9]+)?)", namespace="${service.namespace}", cluster="${job.tag}"} and on(pod, namespace, cluster) (container_start_time_seconds > ${service.expected_start_delay})) or vector(0)
      - alert: ${replace(title(replace(job.tag, "-", " ")), " ", "")}${replace(title(replace(service.name, "-", " ")), " ", "")}TooFewInstancesRunning
        expr: ${replace(job.tag, "-", "_")}_${replace(service.name, "-", "_")}_running_pods:count < ${service.expected_min_count}
        for: 15m
%{ if length(service.alert_labels) > 0 ~}
        labels:
%{ for key, val in service.alert_labels ~}
          ${key}: "${val}"
%{ endfor ~}
%{ endif ~}
        annotations:
          summary: "Service ${title(replace(service.name, "-", " "))} in Kubernetes cluster ${title(replace(job.tag, "-", " "))} has too few running instances"
          description: "Expected at least *${service.expected_min_count}* instances to run. *{{ $value }}* are actually running."
%{ endfor ~}