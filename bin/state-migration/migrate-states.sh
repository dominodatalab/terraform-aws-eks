#!/usr/bin/env bash
set -euo pipefail

validate_vars() {
  for var_name in "${required_vars[@]}"; do
    if [ -z "${!var_name// /}" ]; then
      echo "Error: $var_name is not set or is empty."
      exit 1
    fi
  done
}

legacy_state="${LEGACY_DIR}/terraform.tfstate"

migrate_cluster_state() {

  echo "Migrating EKS module state"
  mkdir -p "$CLUSTER_DIR"
  terraform -chdir="$CLUSTER_DIR" init --reconfigure --upgrade

  terraform state mv \
    -state="$legacy_state" \
    -state-out="$CLUSTER_STATE" \
    "${MOD_NAME}.module.eks" module.eks

  ls "$CLUSTER_DIR"
}

migrate_infra_state() {

  echo "Migrating infra state"
  mkdir -p "$INFRA_DIR"
  terraform -chdir="$INFRA_DIR" init --reconfigure --upgrade

  terraform state mv \
    -state="$legacy_state" \
    -state-out="$INFRA_STATE" \
    "${MOD_NAME}" module.infra

  terraform state rm -state="$INFRA_STATE" 'module.infra.aws_iam_role_policy_attachment.route53[0]'

  ls "$INFRA_DIR"
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
    mapfile -t tmp_array < <(terraform state list -state="$CLUSTER_STATE" | grep "$resource")
    nodes_resources+=("${tmp_array[@]}")
  done

  echo "Migrating nodes state"

  mkdir -p "$NODES_DIR"

  terraform -chdir="$NODES_DIR" init --reconfigure --upgrade

  for resource in "${nodes_resources[@]}"; do
    echo "Migrating nodes resource: $resource"

    terraform state mv \
      -state="$CLUSTER_STATE" \
      -state-out="$NODES_STATE" \
      "$resource" "module.nodes.${resource#module.eks.}"
  done
}

copy_ssh_key() {
  echo "Copying pvt ssh key"
  cp "$LEGACY_PVT_KEY" "$PVT_KEY" &&
    { echo "Regenerating pub key" && ssh-keygen -y -f "$PVT_KEY" >"${PVT_KEY}.pub"; }
}

adjust_vars() {
  [ "$CI_DEPLOY" == "true" ] && bash "${SH_DIR}/ci-deploy.sh" 'set_tf_vars'
}

refresh_all() {
  bash "${DEPLOY_DIR}/tf.sh" refresh all
}

cleanup() {
  echo "Deleting terraform state backup files"
  find . -type f -name "*.tfstate.*.backup*" -print0 -delete
}

migrate_all() {
  migrate_cluster_state
  migrate_infra_state
  migrate_nodes_state

}

#Set DEPLOY_DIR

if [ -z "${DEPLOY_DIR// /}" ]; then
  echo "DEPLOY_DIR is not set"
  exit 1
fi

source "${DEPLOY_DIR}/meta.sh" || { echo "${DEPLOY_DIR}/meta.sh is not present" && exit 1; }

[ "$CI_DEPLOY" == "true" ] && MOD_NAME="module.$(jq -r '.module[0] | keys[0]' ${LEGACY_DIR}/main.tf.json)"

declare -a required_vars=(
  "MOD_NAME"
  "LEGACY_DIR"
  "CLUSTER_DIR"
  "CLUSTER_STATE"
  "INFRA_DIR"
  "INFRA_STATE"
  "NODES_DIR"
  "NODES_STATE"
  "LEGACY_PVT_KEY"
  "PVT_KEY"
)

echo "Running state migration !!!"
validate_vars
migrate_all
copy_ssh_key
adjust_vars
refresh_all
cleanup

echo "State migration completed successfully !!!" && touch "migrated.txt"
