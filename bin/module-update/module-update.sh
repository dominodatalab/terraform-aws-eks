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

set_import() {
  local mod_dir="$1"
  local import_file_tmp="$2"

  local import_file="${mod_dir}/imports.tf"

  if [[ ! -f "$import_file" ]] || ! grep -Fqx -f "$import_file_tmp" "$import_file"; then
    printf "Adding import from %s to %s.\n\n" "$import_file_tmp" "$import_file"
    printf "Import file:\n"
    tee -a "$import_file" <"$import_file_tmp"
  else
    printf "Import on %s already present on %s.\n" "$import_file" "$import_file_tmp"
  fi

  rm -f "$import_file_tmp"
}

set_efs_mount_targets_imports() {
  local import_file_tmp="${INFRA_DIR}/imports.tf.tmp"
  local deploy_id

  # Check if Terraform state file exists
  if [[ ! -f "$INFRA_STATE" ]]; then
    printf "Error: Terraform state file %s does not exist.\n" "$INFRA_STATE"
    return 1
  fi

  # Get deploy_id from INFRA_VARS
  deploy_id=$(hcledit attribute get deploy_id -f "$INFRA_VARS" | jq -r) || {
    printf "Error: Failed to retrieve deploy_id from %s.\n" "$INFRA_VARS"
    return 1
  }

  : >"$import_file_tmp"
  printf "Generating import blocks for EFS mount targets from Terraform state.\n"

  # Extract filesystem matching deploy_id
  fs_json=$(jq -r --arg deploy_id "$deploy_id" \
    '.resources[] | select(.type == "aws_efs_file_system") | .instances[] | select(.attributes.tags.Name == $deploy_id)' "$INFRA_STATE") || {
    printf "Error: Failed to extract filesystem from state file.\n"
    return 1
  }

  # Check if filesystem exists
  if [[ -z "$fs_json" ]]; then
    printf "No EFS filesystem found with deploy_id:%s in state file.\n" "$deploy_id"
    return 0
  fi

  # Extract filesystem ID
  fs_id=$(echo "$fs_json" | jq -r '.attributes.id')

  if [[ -z "${fs_id// /}" ]]; then
    printf "Error: Filesystem ID is empty.\n"
    return 1
  fi

  printf "Processing filesystem: %s\n" "$fs_id"

  # Extract mount targets for this filesystem where index_key is an integer
  mount_targets=$(jq -r --arg fs_id "$fs_id" \
    '.resources[] | select(.type == "aws_efs_mount_target") | .instances[] | select(.attributes.file_system_id == $fs_id and (.index_key | type == "number")) | [.attributes.id, .attributes.subnet_id]' "$INFRA_STATE") || {
    printf "Error: Failed to extract mount targets.\n"
    return 1
  }

  # Check if there are any mount targets with integer index_key
  if [[ -z "$mount_targets" ]]; then
    printf "No mount targets with integer index_key found for filesystem %s. No migration needed.\n" "$fs_id"
    return 0
  fi

  # Extract subnet mapping from outputs
  subnet_map=$(jq -r '.outputs.infra.value.network.subnets.private | map({(.subnet_id): .name}) | add' "$INFRA_STATE") || {
    printf "Error: Failed to extract subnet mapping.\n"
    return 1
  }

  # Generate import blocks for each mount target with integer index_key
  echo "$mount_targets" | jq -c '.' | while read -r mount_point; do
    mount_target_id=$(echo "$mount_point" | jq -r '.[0]')
    subnet_id=$(echo "$mount_point" | jq -r '.[1]')
    subnet_name=$(echo "$subnet_map" | jq -r ".\"$subnet_id\"")
    if [[ -z "$subnet_name" ]]; then
      printf "Warning: No subnet name found for subnet_id %s, skipping.\n" "$subnet_id"
      continue
    fi
    cat <<-EOF >>"$import_file_tmp"
import {
  to = module.infra.module.storage.aws_efs_mount_target.eks_cluster["$subnet_name"]
  id = "$mount_target_id"
}
EOF
  done

  printf "Mount targets with integer index_key found. Migration needed for filesystem %s.\n" "$fs_id"
  set_import "$INFRA_DIR" "$import_file_tmp"
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

  if [ "$(printf '%s\n' "3.25.0" "$MOD_VERSION_NUM" | sort -V | head -n 1)" = "3.25.0" ]; then
    # https://github.com/dominodatalab/terraform-aws-eks/releases/tag/3.25.0
    set_efs_mount_targets_imports
  fi

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
