#!/bin/bash
# User data script for Karpenter nodes - Comprehensive Platform

# Set cluster name
CLUSTER_NAME="${cluster_name}"

# Configure kubelet
/etc/eks/bootstrap.sh $CLUSTER_NAME

# Install additional packages
yum update -y
yum install -y amazon-efs-utils htop iotop

# Configure log rotation
cat > /etc/logrotate.d/kubelet << EOF
/var/log/pods/*/*/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF

# Set up node monitoring
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time",
                    "read_bytes",
                    "write_bytes",
                    "reads",
                    "writes"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/eks/$CLUSTER_NAME/system",
                        "log_stream_name": "{instance_id}/messages"
                    },
                    {
                        "file_path": "/var/log/secure",
                        "log_group_name": "/aws/eks/$CLUSTER_NAME/system",
                        "log_stream_name": "{instance_id}/secure"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Configure node labels and taints
cat > /etc/kubernetes/kubelet/kubelet-config.json << EOF
{
    "kind": "KubeletConfiguration",
    "apiVersion": "kubelet.config.k8s.io/v1beta1",
    "authentication": {
        "anonymous": {
            "enabled": false
        },
        "webhook": {
            "cacheTTL": "2m0s",
            "enabled": true
        },
        "x509": {
            "clientCAFile": "/etc/kubernetes/pki/ca.crt"
        }
    },
    "authorization": {
        "mode": "Webhook",
        "webhook": {
            "cacheAuthorizedTTL": "5m0s",
            "cacheUnauthorizedTTL": "30s"
        }
    },
    "clusterDomain": "cluster.local",
    "clusterDNS": [
        "10.100.0.10"
    ],
    "containerRuntimeEndpoint": "unix:///run/containerd/containerd.sock",
    "cgroupDriver": "systemd",
    "cgroupRoot": "/",
    "featureGates": {
        "RotateKubeletServerCertificate": true
    },
    "healthzBindAddress": "127.0.0.1",
    "healthzPort": 10248,
    "httpCheckFrequency": "20s",
    "imageMinimumGCAge": "2m0s",
    "imageGCHighThresholdPercent": 85,
    "imageGCLowThresholdPercent": 80,
    "iptablesDropBit": 15,
    "iptablesMasqueradeBit": 15,
    "kubeAPIBurst": 10,
    "kubeAPIQPS": 5,
    "makeIPTablesUtilChains": true,
    "maxOpenFiles": 1000000,
    "maxPods": 110,
    "nodeStatusUpdateFrequency": "10s",
    "oomScoreAdj": -999,
    "podPidsLimit": -1,
    "registryBurst": 10,
    "registryPullQPS": 5,
    "resolvConf": "/etc/resolv.conf",
    "rotateCertificates": true,
    "runtimeRequestTimeout": "2m0s",
    "serializeImagePulls": true,
    "serverTLSBootstrap": true,
    "streamingConnectionIdleTimeout": "4h0m0s",
    "syncFrequency": "1m0s",
    "volumeStatsAggPeriod": "1m0s"
}
EOF

# Configure containerd
cat > /etc/containerd/config.toml << EOF
version = 2
root = "/var/lib/containerd"
state = "/run/containerd"

[grpc]
  address = "/run/containerd/containerd.sock"
  uid = 0
  gid = 0
  max_recv_message_size = 16777216
  max_send_message_size = 16777216

[ttrpc]
  address = "/run/containerd/containerd.sock.ttrpc"
  uid = 0
  gid = 0

[debug]
  address = ""
  uid = 0
  gid = 0
  level = ""

[metrics]
  address = ""
  grpc_histogram = false

[cgroup]
  path = ""

[timeouts]
  "io.containerd.timeout.shim.cleanup" = "5s"
  "io.containerd.timeout.shim.load" = "5s"
  "io.containerd.timeout.shim.shutdown" = "3s"
  "io.containerd.timeout.task.state" = "2s"

[plugins]
  [plugins."io.containerd.gc.v1.scheduler"]
    pause_threshold = 0.02
    deletion_threshold = 0
    mutation_threshold = 100
    schedule_delay = "0s"
    startup_delay = "100ms"
  [plugins."io.containerd.grpc.v1.cri"]
    disable_tcp_service = true
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    stream_idle_timeout = "4h0m0s"
    enable_selinux = false
    selinux_category_range = 1024
    sandbox_image = "602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5"
    stats_collect_period = 10
    systemd_cgroup = false
    enable_tls_streaming = false
    max_container_log_line_size = 16384
    disable_cgroup = false
    disable_apparmor = false
    restrict_oom_score_adj = false
    max_concurrent_downloads = 3
    disable_proc_mount = false
    unset_seccomp_profile = ""
    tolerate_missing_hugetlb_controller = true
    ignore_image_defined_volumes = false
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
      default_runtime_name = "runc"
      no_pivot = false
      disable_snapshot_annotations = true
      discard_unpacked_layers = false
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          runtime_engine = ""
          runtime_root = ""
          privileged_without_host_devices = false
          base_runtime_spec = ""
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
      max_conf_num = 1
      conf_template = ""
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.us-west-2.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.us-west-2.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.us-west-2.amazonaws.com.cn"]
          endpoint = ["https://602401143452.dkr.ecr.us-west-2.amazonaws.com.cn"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.cn-northwest-1.amazonaws.com.cn"]
          endpoint = ["https://602401143452.dkr.ecr.cn-northwest-1.amazonaws.com.cn"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."602401143452.dkr.ecr.us-west-2.amazonaws.com".tls]
          insecure_skip_verify = true
        [plugins."io.containerd.grpc.v1.cri".registry.configs."602401143452.dkr.ecr.us-west-2.amazonaws.com.cn".tls]
          insecure_skip_verify = true
        [plugins."io.containerd.grpc.v1.cri".registry.configs."602401143452.dkr.ecr.cn-northwest-1.amazonaws.com.cn".tls]
          insecure_skip_verify = true
    [plugins."io.containerd.grpc.v1.cri".image_decryption]
      key_model = ""
    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = ""
      tls_private_key_file = ""
EOF

# Restart containerd
systemctl restart containerd

# Configure node for better performance
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
echo 'fs.file-max=65536' >> /etc/sysctl.conf
sysctl -p

# Configure limits
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Set up node maintenance script
cat > /usr/local/bin/node-maintenance.sh << 'EOF'
#!/bin/bash
# Node maintenance script

# Clean up unused images
docker system prune -f

# Clean up unused volumes
docker volume prune -f

# Clean up old logs
find /var/log -name "*.log" -type f -mtime +7 -delete

# Update package cache
yum makecache

echo "Node maintenance completed at $(date)"
EOF

chmod +x /usr/local/bin/node-maintenance.sh

# Set up cron job for maintenance
echo "0 2 * * * /usr/local/bin/node-maintenance.sh" | crontab -

echo "Node initialization completed successfully"
