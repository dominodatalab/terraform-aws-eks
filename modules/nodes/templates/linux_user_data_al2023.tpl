MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"
%{ if try(length(pre_bootstrap_user_data), 0) > 0 ~}

--BOUNDARY
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e
${pre_bootstrap_user_data}
%{ endif ~}

--BOUNDARY
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e

%{ if soci_snapshotter.enabled ~}
# SOCI Snapshotter Configuration
# Documentation: https://github.com/awslabs/soci-snapshotter/blob/main/docs/parallel-mode.md
# Tuning Guide: https://github.com/awslabs/soci-snapshotter/blob/main/docs/eks.md
SOCI_CONFIG_FILE="/etc/soci-snapshotter-grpc/config.toml"
%{ if soci_snapshotter.max_concurrent_downloads_per_image != null ~}
max_concurrent_downloads_per_image="${soci_snapshotter.max_concurrent_downloads_per_image}"
sed -i "s/^max_concurrent_downloads_per_image = .*$/max_concurrent_downloads_per_image = $max_concurrent_downloads_per_image/" "$${SOCI_CONFIG_FILE}"
%{ endif ~}
%{ if soci_snapshotter.max_concurrent_unpacks_per_image != null ~}
max_concurrent_unpacks_per_image="${soci_snapshotter.max_concurrent_unpacks_per_image}"
sed -i "s/^max_concurrent_unpacks_per_image = .*$/max_concurrent_unpacks_per_image = $max_concurrent_unpacks_per_image/" "$${SOCI_CONFIG_FILE}"
%{ endif ~}
%{ endif ~}

--BOUNDARY
Content-Type: application/node.eks.aws

---
# EKS NodeConfig API for AL2023
# Documentation: https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
# Examples: https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/examples/
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${cluster_name}
    apiServerEndpoint: ${cluster_endpoint}
    certificateAuthority: ${cluster_auth_base64}
%{ if try(length(cluster_service_ipv4_cidr), 0) > 0 ~}
    cidr: ${cluster_service_ipv4_cidr}
%{ endif ~}
%{ if soci_snapshotter.enabled || length(feature_gates) > 0 ~}
  # Feature Gates
  # EKS Feature Gates: https://docs.aws.amazon.com/eks/latest/userguide/al2023.html
  # Kubernetes Feature Gates: https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/
  featureGates:
%{ if soci_snapshotter.enabled ~}
    # FastImagePull enables SOCI snapshotter integration
    # Documentation: https://github.com/awslabs/soci-snapshotter/blob/main/docs/eks.md
    FastImagePull: ${soci_snapshotter.enabled}
%{ endif ~}
%{ for gate, enabled in feature_gates ~}
    ${gate}: ${enabled}
%{ endfor ~}
%{ endif ~}
  kubelet:
    config:
      # Kubelet image pull rate limiting configuration
      # Documentation: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration
      registryPullQPS: ${registry_pull_qps}
      registryBurst: ${registry_burst}
%{ if try(length(bootstrap_extra_args), 0) > 0 ~}
    flags:
    ${bootstrap_extra_args}
%{ endif ~}

--BOUNDARY--
