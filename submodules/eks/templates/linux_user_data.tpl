#!/bin/bash
set -e
${pre_bootstrap_user_data ~}
%{ if length(cluster_service_ipv4_cidr) > 0 ~}
export SERVICE_IPV4_CIDR=${cluster_service_ipv4_cidr}
%{ endif ~}
B64_CLUSTER_CA=${cluster_auth_base64}
API_SERVER_URL=${cluster_endpoint}
EKS_CONTAINERD_CFG="/etc/eks/containerd/containerd-config.toml"
if [ -z "$(egrep 'certs\.d' $EKS_CONTAINERD_CFG)" ]; then
    if [ -n "$(egrep 'plugins\.cri\.containerd\.runtimes\.nvidia' $EKS_CONTAINERD_CFG)" ]; then
        printf '\n\n[plugins.cri.registry]\nconfig_path = "/etc/containerd/certs.d:/etc/docker/certs.d"\n' >> $EKS_CONTAINERD_CFG
    fi
fi
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_extra_args} --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL
${post_bootstrap_user_data ~}
