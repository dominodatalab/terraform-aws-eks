#!/usr/bin/env bash

set -euo pipefail

CLUSTER_DIR="./cluster"
NODES_DIR="./nodes"
INFRA_DIR="./infra"

mod_name="module.$(jq -r '.module[0] | keys[0]' main.tf.json)"

migrate_cluster_state() {

  echo "Migrating EKS module state"
  mkdir -p "${CLUSTER_DIR}"
  terraform -chdir="${CLUSTER_DIR}" init --reconfigure --upgrade

  terraform state mv \
    -state="terraform.tfstate" \
    -state-out="${CLUSTER_DIR}/terraform.tfstate" \
    "${mod_name}.module.eks" module.eks

  ls "${CLUSTER_DIR}"
}

migrate_infra_state() {

  echo "Migrating infra"
  mkdir -p "${INFRA_DIR}"
  terraform -chdir="${INFRA_DIR}" init --reconfigure --upgrade

  terraform state mv \
    -state="terraform.tfstate" \
    -state-out="${INFRA_DIR}/terraform.tfstate" \
    "${mod_name}" module.infra

  terraform -chdir="${INFRA_DIR}" state rm 'module.infra.aws_iam_role_policy_attachment.route53[0]'

  ls "${INFRA_DIR}"
}

run_tf_refresh() {
  DIR="${1// /}"
  terraform -chdir="${DIR}" apply -refresh-only --auto-approve -input=false
}

migrate_nodes_state() {

  declare -a nodes_resource_definitions=(
    'aws_autoscaling_group_tag.tag'
    'aws_eks_addon.this'
    'aws_eks_node_group.node_groups'
    'aws_launch_template.node_groups'
    'terraform_data.calico_setup'
  )

  declare -a nodes_resources=()

  for resource in "${nodes_resource_definitions[@]}"; do
    mapfile -t tmp_array < <(terraform state list -state="${CLUSTER_DIR}/terraform.tfstate" | grep "${resource}")
    nodes_resources+=("${tmp_array[@]}")
  done

  echo "Migrating nodes"

  mkdir -p "${NODES_DIR}"

  terraform -chdir="${NODES_DIR}" init --reconfigure --upgrade

  terraform -chdir="${NODES_DIR}" init

  for resource in "${nodes_resources[@]}"; do
    echo "Migrating resource $resource"

    terraform state mv \
      -state="${CLUSTER_DIR}/terraform.tfstate" \
      -state-out="${NODES_DIR}/terraform.tfstate" \
      "${resource}" "module.nodes.${resource#module.eks.}"
  done
}

refresh_all() {
  run_tf_refresh "${INFRA_DIR}"
  run_tf_refresh "${CLUSTER_DIR}"
  run_tf_refresh "${NODES_DIR}"
}

echo "Running state migration!!!"

migrate_cluster_state
migrate_infra_state
migrate_nodes_state

refresh_all

touch "migrated.txt"
