#!/usr/bin/env bash
set -euo pipefail

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# ci vars
echo "Getting CI vars"
source "${SH_DIR}/meta.sh"

# module vars
if test -f "${DEPLOY_DIR}/meta.sh"; then
  echo "Getting module vars"
  source "${DEPLOY_DIR}/meta.sh"
fi

# remote module vars
BASE_REMOTE_SRC="github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git"
BASE_REMOTE_MOD_SRC="${BASE_REMOTE_SRC}//modules"

github_curl() {
  local url="$1"
  shift
  local curl_args=(
    -fsSL
    --retry 5
    --retry-delay 2
    --retry-all-errors
  )

  if [ -n "${GITHUB_READONLY_TOKEN:-}" ]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_READONLY_TOKEN}")
  fi

  curl_args+=("$@")
  curl "${curl_args[@]}" "$url"
}

get_latest_release_tag() {
  if [ -z "${LATEST_REL_TAG:-}" ]; then
    LATEST_REL_TAG="$(github_curl "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/latest" \
      --retry 15 --retry-delay 5 \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Accept: application/vnd.github+json" | jq -r '.tag_name')"
    export LATEST_REL_TAG
  fi
}

deploy() {
  component=${1:-all}
  pushd "$DEPLOY_DIR" >/dev/null
  for tf_cmd in 'init' 'validate' 'apply'; do
    bash "./tf.sh" "$component" "$tf_cmd" || {
      echo "Terraform $tf_cmd failed. Exiting..."
      return 1
    }
  done
  popd >/dev/null 2>&1
}

set_ci_branch_name() {
  if [[ "$CIRCLE_BRANCH" =~ ^pull/[0-9]+/head$ ]]; then
    PR_NUMBER=$(echo "$CIRCLE_BRANCH" | sed -n 's/^pull\/\([0-9]*\)\/head/\1/p')
    ci_branch_name=$(github_curl "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls/${PR_NUMBER}" \
      --retry 15 --retry-delay 5 \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Accept: application/vnd.github+json" | jq -r .head.ref)
  else
    ci_branch_name="$CIRCLE_BRANCH"
  fi
  CI_BRANCH_NAME=$(jq -rn --arg br "$ci_branch_name" '$br|@uri')
  export CI_BRANCH_NAME
}

setup_module() {
  local deploy_dir="$1"
  local repo_ref="$2"

  rm -rf "$deploy_dir"
  mkdir -p "$deploy_dir"
  echo "Running init from module: -from-module=${BASE_REMOTE_SRC}//examples/deploy?ref=${repo_ref} at: $deploy_dir"
  terraform -chdir="$deploy_dir" init -backend=false -from-module="${BASE_REMOTE_SRC}//examples/deploy?ref=${repo_ref}"
}

setup_modules_ci_branch() {
  set_ci_branch_name
  setup_module "$DEPLOY_DIR" "$CI_BRANCH_NAME"
}

setup_modules_latest_rel() {
  get_latest_release_tag
  setup_module "$DEPLOY_DIR" "$LATEST_REL_TAG"
}

setup_modules_upgrade() {
  rsync -ra --exclude '.terraform*' ../../examples/deploy/ "$DEPLOY_DIR"
}

install_helm() {
  if [ -z "$HELM_VERSION" ]; then
    echo "HELM_VERSION environment variable not set, exiting."
    exit 1
  fi
  echo "Installing Helm version: ${HELM_VERSION}"
  github_curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh
  chmod +x get_helm.sh
  ./get_helm.sh --version "${HELM_VERSION}"
  rm ./get_helm.sh
  helm version --short
}

install_hcledit() {
  local hcledit_version="${HCLEDIT_VERSION}"
  local hcledit_artifact="hcledit_${hcledit_version}_linux_amd64.tar.gz"
  github_curl "https://github.com/minamijoyo/hcledit/releases/download/v${hcledit_version}/${hcledit_artifact}" -o "${hcledit_artifact}"
  tar xvzf "${hcledit_artifact}"
  sudo mv hcledit /usr/local/bin/ && rm "${hcledit_artifact}" && hcledit version
}

install_opentofu() {
  local opentofu_version="${OPENTOFU_VERSION}"
  local opentofu_artifact="tofu_${opentofu_version}_linux_amd64.tar.gz"
  github_curl "https://github.com/opentofu/opentofu/releases/download/v${opentofu_version}/${opentofu_artifact}" -o "${opentofu_artifact}"
  tar xvzf "${opentofu_artifact}"
  sudo mv tofu /usr/local/bin/ && rm "${opentofu_artifact}" && tofu version
  sudo ln -s /usr/local/bin/tofu /usr/local/bin/terraform && terraform version
}

set_eks_worker_ami() {
  # We can potentially test AMI upgrades in CI.
  # 1 is latest.
  local precedence="$1"
  local ami_pattern

  ami_pattern="amazon-eks-node-al2023-x86_64-standard-${K8S_VERSION// /}*"
  AMI_USER_DATA_TYPE="AL2023"

  if ! aws sts get-caller-identity; then
    echo "Incorrect AWS credentials."
    exit 1
  fi

  CUSTOM_AMI="$(aws ec2 describe-images --region us-west-2 --owners '602401143452' --filters "Name=owner-alias,Values=amazon" "Name=architecture,Values=x86_64" "Name=name,Values=${ami_pattern}" --query "sort_by(Images, &CreationDate) | [-${precedence}].ImageId" --output text)"

  export CUSTOM_AMI AMI_USER_DATA_TYPE
}

get_branch_being_deployed() {
  echo "Getting branch being deployed"
  BRANCH_BEING_DEPLOYED=$(tr -d '\n' < "$DEPLOYMENT_BRANCH_TRACKING_FILE")
  if [ -z "$BRANCH_BEING_DEPLOYED" ]; then
    echo "BRANCH_BEING_DEPLOYED is not set."
    exit 1
  fi
  echo "BRANCH_BEING_DEPLOYED: $BRANCH_BEING_DEPLOYED"
  export BRANCH_BEING_DEPLOYED
}

  # Using modules/eks/variables.tf as the source of truth for the k8s version.
  # Allows for the upgrade flow to test k8s upgrades.
get_k8s_version() {
  echo "Getting k8s version"
  K8S_VERSION=$(github_curl "https://raw.githubusercontent.com/dominodatalab/terraform-aws-eks/${BRANCH_BEING_DEPLOYED}/modules/eks/variables.tf" | \
  awk '/k8s_version.*optional.*string/ {match($0, /"[0-9.]+"/); print substr($0, RSTART+1, RLENGTH-2)}')

  if [ -z "$K8S_VERSION" ]; then
    echo "K8S_VERSION is not set."
    exit 1
  fi
  echo "K8S_VERSION: $K8S_VERSION"
  export K8S_VERSION
}

set_tf_vars() {
  get_branch_being_deployed

  get_k8s_version

  set_eks_worker_ami '1'
  if [ -z $CUSTOM_AMI ]; then
    echo 'CUSTOM_AMI is not set.'
    # We want to test passing an ami.
    exit 1
  fi
  if [ -z "$AMI_USER_DATA_TYPE" ]; then
    echo "AMI_USER_DATA_TYPE is not set."
    exit 1
  fi

  [ -f "$PVT_KEY" ] || { ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f "$PVT_KEY" && chmod 600 "$PVT_KEY"; }

  # Set safe-to-delete timestamp (4 hours from now in UTC)
  CI_SAFE_DELETE_AFTER=$(date -u -d '+4 hours' +%Y-%m-%dT%H:%M:%SZ)

  export CUSTOM_AMI AMI_USER_DATA_TYPE PVT_KEY CI_SAFE_DELETE_AFTER

  printf "\nInfra vars:\n"
  envsubst <"$INFRA_VARS_TPL" | tee "$INFRA_VARS"

  DEFAULT_NODES=$(hcledit attribute get default_node_groups -f "$INFRA_VARS")
  ADDITIONAL_NODES=$(hcledit attribute get additional_node_groups -f "$INFRA_VARS")
  KARPENTER_NODES=$(hcledit attribute get karpenter_node_groups -f "$INFRA_VARS")

  export DEFAULT_NODES ADDITIONAL_NODES KARPENTER_NODES

  printf "\nCluster vars:\n"
  envsubst <"$CLUSTER_VARS_TPL" | tee "$CLUSTER_VARS"

  printf "\nNodes vars:\n"
  envsubst <"$NODES_VARS_TPL" | tee "$NODES_VARS"
}

# Not used atm, but we could test nodes upgrades(OS-patches).
deploy_latest_ami_nodes() {
  ## Setting the default_node_groups.compute.ami to null ensures latest.
  export CUSTOM_AMI=null
  set_tf_vars
  deploy 'nodes'
}

set_infra_imports() {
  local import_file_tmp="${INFRA_DIR}/imports.tf.tmp"
  local deploy_id

  if [[ ! -f "$INFRA_STATE" ]]; then
    printf "Error: Terraform state file %s does not exist.\n" "$INFRA_STATE"
    return 1
  fi

  if [[ ! -f "$INFRA_VARS" ]]; then
    printf "Error: Terraform tfvars file %s does not exist.\n" "$INFRA_VARS"
    return 1
  fi

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

  # Check if filesystem exists in the tfstate and exit if not(nothing to migrate)
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

  printf "Mount targets with integer index_key found(use of count instead of for_each). Migration needed for filesystem %s mount targets.\n" "$fs_id"
  set_import "$INFRA_DIR" "$import_file_tmp"
}

# Not used atm, scaffold for seamless future use.
set_cluster_imports() {
  printf "Nothing to import into the cluster module.\n"
  local import_file_tmp="${CLUSTER_DIR}/imports.tf.tmp"
  return 0 # Remove return if used.
  set_import "$CLUSTER_DIR" "$import_file_tmp"
}

set_nodes_imports() {
  local import_file_tmp="${NODES_DIR}/imports.tf.tmp"
  cat <<-EOF >"$import_file_tmp"
import {
  to = module.nodes.aws_eks_addon.pre_compute_addons["vpc-cni"]
  id = "\${local.eks.cluster.specs.name}:vpc-cni"
}
EOF

  set_import "$NODES_DIR" "$import_file_tmp"
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

destroy() {
  local component=${1:-all}
  pushd "$DEPLOY_DIR" >/dev/null
  bash "./tf.sh" "$component" destroy
  popd >/dev/null 2>&1
}

rm_hosted_zone_var_from_infra_module() {
  printf "Removing route53_hosted_zone_private var.\n"

  hcledit block rm variable.route53_hosted_zone_name -u -f "${INFRA_DIR}/variables.tf"
  hcledit block rm variable.route53_hosted_zone_private -u -f "${INFRA_DIR}/variables.tf"

  hcledit attribute rm module.infra.route53_hosted_zone_name -u -f "${INFRA_DIR}/main.tf"
  hcledit attribute rm module.infra.route53_hosted_zone_private -u -f "${INFRA_DIR}/main.tf"

  cat "${INFRA_DIR}/main.tf"
  cat "${INFRA_DIR}/variables.tf"
}

pre_upgrade_updates() {
  printf "Running pre-upgrade updates.\n"
  rm_hosted_zone_var_from_infra_module
}

set_mod_src() {
  local mod_source="$1"
  local tf_file="$2"
  local name="$3"

  hcledit attribute set "module.${name}.source" "\"${mod_source}\"" -u -f "$tf_file"
  cat "$tf_file"
}

set_all_mod_src() {
  local ref="$1"
  local base_local_mod_src="./../../../../../modules"

  for dir in "${MOD_DIRS[@]}"; do
    IFS=' ' read -ra MODS <<<"${COMP_MODS[$(basename "$dir")]}"
    for mod in "${MODS[@]}"; do
      mod_add=${MOD_ADD[$mod]-"$mod"}
      if [ "$ref" == "local" ]; then
        MOD_SOURCE="${base_local_mod_src}/${mod_add}"
      else
        MOD_SOURCE="${BASE_REMOTE_MOD_SRC}/${mod_add}?ref=${ref}"
      fi
      echo "Setting module source to ref: ${MOD_SOURCE} on ${dir}"
      set_mod_src "$MOD_SOURCE" "${dir}/main.tf" "$mod"
    done
  done
}



deploy_infra() {
  deploy "infra"
}

deploy_cluster() {
  deploy "cluster"
}

deploy_nodes() {
  deploy "nodes"
}

# Need to track whats the branch being deployed in order to grab the default k8s version.
track_deployment_branch() {
  local branch="$1"
  echo "Updating ${DEPLOYMENT_BRANCH_TRACKING_FILE}: ${branch}"
  echo "${branch}" > "$DEPLOYMENT_BRANCH_TRACKING_FILE"
}

set_mod_src_circle_branch() {
  set_ci_branch_name
  set_all_mod_src "$CI_BRANCH_NAME"
  track_deployment_branch "$CI_BRANCH_NAME"
}

set_mod_src_local() {
  echo "Updating module source to local."
  set_all_mod_src "local"
}


set_mod_src_latest_rel() {
  get_latest_release_tag
  echo "Updating module source to the latest published release: ${LATEST_REL_TAG}"
  set_all_mod_src "$LATEST_REL_TAG"
  track_deployment_branch "$LATEST_REL_TAG"
}

for arg in "$@"; do
  "$arg"
done
