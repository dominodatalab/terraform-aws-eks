#!/bin/bash

set -e

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
nodeclasses_dir="${SH_DIR}/ec2nodeclasses"
nodepools_dir="${SH_DIR}/nodepools"
nodeclasses_template_dir="${SH_DIR}/templates/ec2nodeclasses"
nodepools_template_dir="${SH_DIR}/templates/nodepools"

usage() {
  echo "Usage: $0 [render|get-ami|apply]"
  echo "  render    - Render the configuration templates"
  echo "  get-ami   - Get the latest AMI and render templates"
  echo "  apply     - Apply the configurations using kubectl"
  exit 1
}

check_directories() {
  if [ ! -d "$nodeclasses_template_dir" ]; then
    echo "Error: nodeclasses directory not found"
    echo "Please run this script from the karpenter directory"
    exit 1
  fi

  if [ ! -d "$nodepools_template_dir" ]; then
    echo "Error: nodepools directory not found"
    echo "Please run this script from the karpenter directory"
    exit 1
  fi
}

check_yaml_templates() {
  if ! ls "$nodeclasses_template_dir"/*.yaml 1>/dev/null 2>&1; then
    echo "Error: No YAML files found in nodeclasses directory"
    exit 1
  fi

  if ! ls "$nodepools_template_dir"/*.yaml 1>/dev/null 2>&1; then
    echo "Error: No YAML files found in nodepools directory"
    exit 1
  fi
}

check_yaml_files() {
  if ! ls "$nodeclasses_dir"/*.yaml 1>/dev/null 2>&1; then
    echo "Error: No YAML files found in nodeclasses directory"
    exit 1
  fi

  if ! ls "$nodepools_dir"/*.yaml 1>/dev/null 2>&1; then
    echo "Error: No YAML files found in nodepools directory"
    exit 1
  fi
}

render_templates() {
  mkdir -p "$nodeclasses_dir" "$nodepools_dir"

  echo "Rendering templates..."
  export EKS_NODES_ROLE_NAME=$(./tf.sh cluster output_json eks | jq -r '.eks.value.nodes.roles[0].name')
  export EKS_CLUSTER_NAME=$(./tf.sh cluster output_json eks | jq -r '.eks.value.cluster.specs.name')
  export AWS_REGION=$(./tf.sh cluster output_json eks | jq -r '.infra.value.region')

  AL2023_AMI_ALIAS_VERSION="$(aws ssm get-parameter \
    --name /aws/service/eks/optimized-ami/1.31/amazon-linux-2023/x86_64/standard/recommended/image_name \
    --query 'Parameter.Value' \
    --output text | awk -F'-' '{print $NF}')"

  AL2023_AMI_ALIAS="al2023@${AL2023_AMI_ALIAS_VERSION}"
  export AL2023_AMI_ALIAS
  echo "Setting AMI alias to $AL2023_AMI_ALIAS"

  for nc in "$nodeclasses_template_dir"/*.yaml; do
    echo "Rendering $nc..."
    cat "$nc" | envsubst >"${nodeclasses_dir}/$(basename "$nc")"
  done

  for np in "$nodepools_template_dir"/*.yaml; do
    echo "Rendering $np..."
    cat "$np" | envsubst >"${nodepools_dir}/$(basename "$np")"
  done
}

apply_nodeclasses() {
  echo "Applying nodeclasses..."
  for file in "$nodeclasses_dir"/*.yaml; do
    echo "Applying $file..."
    kubectl apply -f "$file"
  done
}

apply_nodepools() {
  echo "Applying nodepools..."
  for file in "$nodepools_dir"/*.yaml; do
    echo "Applying $file..."
    kubectl apply -f "$file"
  done
}

render() {
  check_yaml_templates &&
    render_templates
}

apply() {
  check_yaml_files || {
    echo "Failed to verify YAML files"
    return 1
  }

  if ! source "k8s-functions.sh"; then
    echo "Error: Failed to source k8s-functions.sh"
    return 1
  fi

  if ! open_ssh_tunnel_to_k8s_api; then
    echo "Error: Failed to open SSH tunnel to Kubernetes API"
    return 1
  fi

  trap "close_ssh_tunnel_to_k8s_api" EXIT

  if ! check_kubeconfig; then
    echo "Error: Kubeconfig check failed"
    return 1
  fi

  if ! apply_nodeclasses; then
    echo "Error: Failed to apply nodeclasses"
    return 1
  fi

  if ! apply_nodepools; then
    echo "Error: Failed to apply nodepools"
    return 1
  fi
}

if [ $# -ne 1 ]; then
  usage
fi

check_directories

case "$1" in
"render")
  echo "Templates rendered successfully!"
  ;;
"apply")
  apply
  echo "All Karpenter configurations applied successfully!"
  ;;
*)
  usage
  ;;
esac
