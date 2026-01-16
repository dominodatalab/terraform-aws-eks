#!/bin/bash
set -e
%{ if try(length(pre_bootstrap_user_data), 0) > 0 ~}
${pre_bootstrap_user_data}
%{ endif ~}
%{ if try(length(cluster_service_ipv4_cidr), 0) > 0 ~}
export SERVICE_IPV4_CIDR=${cluster_service_ipv4_cidr}
%{ endif ~}
B64_CLUSTER_CA=${cluster_auth_base64}
API_SERVER_URL=${cluster_endpoint}
# Update registryPullQPS and registryBurst
CONFIG_FILE="/etc/kubernetes/kubelet/kubelet-config.json"
if [ -f "$CONFIG_FILE" ]; then
  jq '.registryPullQPS=${registry_pull_qps} | .registryBurst=${registry_burst}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_extra_args} --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL
${post_bootstrap_user_data ~}
