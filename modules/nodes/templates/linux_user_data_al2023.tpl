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

# Update registryPullQPS and registryBurst
CONFIG_FILE="/etc/kubernetes/kubelet/kubelet-config.json"
if [ -f "$CONFIG_FILE" ]; then
  jq '.registryPullQPS=${registry_pull_qps} | .registryBurst=${registry_burst}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

%{ if try(length(soci_snapshotter), 0) > 0 ~}
SOCI_CONFIG_FILE="/etc/soci-snapshotter-grpc/config.toml"
%{ if try(soci_snapshotter.max_concurrent_downloads_per_image, null) != null ~}
max_concurrent_downloads_per_image = "${soci_snapshotter.max_concurrent_downloads_per_image}"
sed -i "s/^max_concurrent_downloads_per_image = .*$/max_concurrent_downloads_per_image = $max_concurrent_downloads_per_image/" "$${SOCI_CONFIG_FILE}"
%{ endif ~}
%{ if try(soci_snapshotter.max_concurrent_unpacks_per_image, null) != null ~}
max_concurrent_unpacks_per_image = "${soci_snapshotter.max_concurrent_unpacks_per_image}"
sed -i "s/^max_concurrent_unpacks_per_image = .*$/max_concurrent_unpacks_per_image = $max_concurrent_unpacks_per_image/" "$${SOCI_CONFIG_FILE}"
%{ endif ~}
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
%{ if try(length(cluster_service_ipv4_cidr), 0) > 0 ~}
    cidr: ${cluster_service_ipv4_cidr}
%{ endif ~}
%{ if try(length(feature_gates), 0) > 0 ~}
  featureGates:
%{ for gate, enabled in feature_gates ~}
    ${gate}: ${enabled}
%{ endfor ~}
%{ endif ~}
%{ if try(soci_snapshotter.max_concurrent_downloads_per_image, null) != null || try(soci_snapshotter.max_concurrent_unpacks_per_image, null) != null ~}
  sociSnapshotter:
    config:
%{ if try(soci_snapshotter.max_concurrent_downloads_per_image, null) != null ~}
      maxConcurrentDownloadsPerImage: ${soci_snapshotter.max_concurrent_downloads_per_image}
%{ endif ~}
%{ if try(soci_snapshotter.max_concurrent_unpacks_per_image, null) != null ~}
      maxConcurrentUnpacksPerImage: ${soci_snapshotter.max_concurrent_unpacks_per_image}
%{ endif ~}
%{ endif ~}
  kubelet:
    config:
      # Configured through UserData since unavailable in `spec.kubelet`
      registryPullQPS: ${registry_pull_qps}
      registryBurst: ${registry_burst}
%{ if try(length(bootstrap_extra_args), 0) > 0 ~}
    flags:
    ${bootstrap_extra_args}
%{ endif ~}

--BOUNDARY--
