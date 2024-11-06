#!/usr/bin/env bash
set -euo pipefail

if [ -z "$DEPLOY_DIR" ]; then
  printf "ERROR: 'DEPLOY_DIR' needs to be set.\nExiting..."
  exit 1
fi

if [ -z "$AWS_REGION" ]; then
  printf "ERROR: 'AWS_REGION' needs to be set.\nExiting..."
  exit 1
fi

if [ ! -d "$DEPLOY_DIR" ] || [ -z "$(ls -A "$DEPLOY_DIR")" ]; then
  printf "ERROR %s does not exist or its empty\nExiting..." "$DEPLOY_DIR"
  exit 1
fi

TIMESTAMP=$(date +"%y-%m-%d")
SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
UPGRADE_DIR="${SH_DIR}/${DEPLOY_DIR}-${TIMESTAMP}"
META_PATH="${SH_DIR}/${DEPLOY_DIR}/meta.sh"
BACKUP_DIR="${DEPLOY_DIR}-BACKUP-${TIMESTAMP}"

[ -f "$META_PATH" ] && source "$META_PATH"

update_hosted_zone_configuration() {

  printf "Hosted zone setup has been moved to IRSA."

  local hosted_zone=$(hcledit attribute get route53_hosted_zone_name -f "${INFRA_VARS}")
  local irsa_external_dns=$(hcledit attribute get "irsa_external_dns" -f "${CLUSTER_VARS}")

  if [ -n "$hosted_zone" ]; then
    if [ -z "$irsa_external_dns" ]; then
      cat <<-EOB >>"$CLUSTER_VARS"
irsa_external_dns = {
  enabled = true
  hosted_zone_name = $hosted_zone
}
EOB
    else
      printf "'irsa_external_dns' already exists on %s.\n" "${CLUSTER_VARS}"
    fi
  fi

  printf "Removing route53_hosted_zone_private var.\n"

  hcledit block rm variable.route53_hosted_zone_name -u -f "${INFRA_DIR}/variables.tf"
  hcledit block rm variable.route53_hosted_zone_private -u -f "${INFRA_DIR}/variables.tf"

  hcledit attribute rm module.infra.route53_hosted_zone_name -u -f "${INFRA_DIR}/main.tf"
  hcledit attribute rm module.infra.route53_hosted_zone_private -u -f "${INFRA_DIR}/main.tf"

  hcledit attribute rm route53_hosted_zone_name -u -f "${INFRA_VARS}"

}

set_vpc_cni_import() {

  local nodes_main_tf_path="${NODES_DIR}/imports.tf"

  if hcledit block get "import" -f "$nodes_main_tf_path" | grep -q 'to = module.nodes.aws_eks_addon.pre_compute_addons\["vpc-cni"\]'; then
    printf 'Import block already exists for module.nodes.aws_eks_addon.pre_compute_addons["vpc-cni"]. \n'
    return
  fi

  printf "Creating import block for 'vpc-cni' EKS addon.\n IMPORTANT: After this configuration is applied and the vpc-cni addon is imported, the %s file can be removed\n" "$nodes_main_tf_path"

  cat <<-EOB >>"$nodes_main_tf_path"
import {
  to = module.nodes.aws_eks_addon.pre_compute_addons["vpc-cni"]
  id = "\${local.eks.cluster.specs.name}:vpc-cni"
}
EOB

  echo
}

update_mod_source() {

  local mod_dir="$1"
  local mod_version="$2"

  local update_mod_sh_path="${mod_dir}/set-mod-version.sh"

  if [ ! -f "$update_mod_sh_path" ]; then
    printf "Unable to find %s\nExiting...\n" "$update_mod_sh_path"
    exit 1
  fi

  "$update_mod_sh_path" "$mod_version"
}

initialize_upgrade_module() {
  if [ -z "$UPGRADE_DIR" ] || [ -z "$MOD_VERSION" ]; then
    printf "UPGRADE_DIR and MOD_VERSION vars need to be set.\nExiting...\n"
    exit 1
  fi

  printf "Creating Upgrade deploy DIR..."
  mkdir -p "$UPGRADE_DIR"

  printf "Initializing module on %s\n" "$UPGRADE_DIR"
  terraform -chdir="$UPGRADE_DIR" init -backend=false -from-module="github.com/dominodatalab/terraform-aws-eks.git//examples/deploy?ref=${MOD_VERSION}"

  printf "Updating module source...\n"
  update_mod_source "$UPGRADE_DIR" "$MOD_VERSION"
}

backup_files() {
  if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
    printf "Backing up %s to %s.\n" "$DEPLOY_DIR" "$BACKUP_DIR"
    cp -r "$DEPLOY_DIR/" "$BACKUP_DIR/"
  else
    printf "%s exists and is not empty. Skipping backup...\n" "$BACKUP_DIR"
  fi
}

copy_updated_files() {
  backup_files
  rsync -av --include={'*.tf','*.sh'} --exclude={'.*/','*.tfvars'} "${UPGRADE_DIR}/" "${DEPLOY_DIR}/"
}

is_vpc_cni_installed() {
  local deploy_id=$(hcledit attribute get deploy_id -f "$INFRA_VARS" | jq -r .)

  if aws eks list-addons --cluster-name "${deploy_id}" --output json | jq -e '.addons | index("vpc-cni")' >/dev/null; then
    return 0
  else
    return 1
  fi
}

update_tfvars_from_module() {
  declare -A tfvars_paths=(
    ["$INFRA_DIR"]=$INFRA_VARS
    ["$CLUSTER_DIR"]="$CLUSTER_VARS"
    ["$NODES_DIR"]="$NODES_VARS"
  )

  for mod_dir in "${!tfvars_paths[@]}"; do
    vars_path="${tfvars_paths[$mod_dir]}"
    if [ "$(basename "$mod_dir")" = "cluster" ] && is_vpc_cni_installed; then
      local deploy_id=$(hcledit attribute get deploy_id -f "$INFRA_VARS" | jq -r .)
      printf "WARNING: The %s EKS cluster has the 'vpc-cni' installed, you will need to add it to the eks addons list(eks.cluster_addons) in %s otherwise the import operation will fail.\n" "$deploy_id" "$INFRA_VARS"
    fi
    tfvar "${mod_dir}" --var-file "${vars_path}" >>"${vars_path}-tmp"
    mv "${vars_path}-tmp" "$vars_path"
  done
}

cleanup() {
  rm -fr "$UPGRADE_DIR"
}

imports_corrections_deprecations() {
  MOD_VERSION_NUM=${MOD_VERSION#v}

  if [ "$(printf '%s\n' "3.6.0" "$MOD_VERSION_NUM" | sort -V | head -n 1)" = "3.6.0" ]; then
    # https://github.com/dominodatalab/terraform-aws-eks/releases/tag/v3.6.0
    update_hosted_zone_configuration
  fi

  if [ "$(printf '%s\n' "3.5.0" "$MOD_VERSION_NUM" | sort -V | head -n 1)" = "3.5.0" ]; then
    # https://github.com/dominodatalab/terraform-aws-eks/releases/tag/v3.5.0
    is_vpc_cni_installed && set_vpc_cni_import
  fi
}

update_tfvars() {
  update_tfvars_from_module
  imports_corrections_deprecations
}

update() {
  initialize_upgrade_module &&
    copy_updated_files &&
    update_tfvars
  cleanup
}

for arg in "$@"; do
  "$arg"
done
