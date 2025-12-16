#!/bin/bash
set -e
${pre_bootstrap_user_data ~}
%{ if length(cluster_service_ipv4_cidr) > 0 ~}
export SERVICE_IPV4_CIDR=${cluster_service_ipv4_cidr}
%{ endif ~}
B64_CLUSTER_CA=${cluster_auth_base64}
API_SERVER_URL=${cluster_endpoint}
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_extra_args} --registry-qps=12 --registry-burst=40 --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL
${post_bootstrap_user_data ~}
