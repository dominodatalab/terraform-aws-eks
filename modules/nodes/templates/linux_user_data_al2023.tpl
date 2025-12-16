MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"
%{ if length(pre_bootstrap_user_data) > 0 ~}

--BOUNDARY
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e
${pre_bootstrap_user_data}
%{ endif ~}

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${cluster_name}
    apiServerEndpoint: ${cluster_endpoint}
    certificateAuthority: ${cluster_auth_base64}
%{ if length(cluster_service_ipv4_cidr) > 0 ~}
    cidr: ${cluster_service_ipv4_cidr}
%{ endif ~}
  kubelet:
    config:
      # Configured through UserData since unavailable in `spec.kubelet`
      registryPullQPS: 12
      registryBurst: 40
    %{ if length(bootstrap_extra_args) > 0 ~}
    flags:
    ${bootstrap_extra_args}
    %{ endif ~}

--BOUNDARY--
