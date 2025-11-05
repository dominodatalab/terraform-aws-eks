#!/usr/bin/env bash
set -euo pipefail

DEFAULT_K8S_VERSION="${1:-1.32}"

echo "Updating Kubernetes version to $DEFAULT_K8S_VERSION"

# Update variable defaults in modules
sed -i.bak -E "s/(k8s_version[[:space:]]*=[[:space:]]*optional\(string,[[:space:]]*\")[0-9.]+(\"\))/\1$DEFAULT_K8S_VERSION\2/" \
  modules/eks/variables.tf \
  modules/infra/variables.tf \
  tests/plan/terraform/variables.tf

sed -i.bak -E "s/(k8s_version[[:space:]]*=[[:space:]]*\")[0-9.]+(\"))/\1$DEFAULT_K8S_VERSION\2/" \
  examples/tfvars/nodes-custom-ami.tfvars

sed -i.bak -E "s/(kubectl.*>= )[0-9.]+/\1$DEFAULT_K8S_VERSION/" \
  README.md

sed -i.bak -E "s/(optimized-ami\/)[0-9.]+\//\1$DEFAULT_K8S_VERSION\//" \
  examples/karpenter/karpenter-configs.sh

# Clean up backup files
find . -name "*.bak" -delete

echo "Updated Kubernetes version to $DEFAULT_K8S_VERSION"
