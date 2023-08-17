#!/usr/bin/env bash
set -euo pipefail

BASE_TF_DIR="terraform"
declare -a MOD_DIRS=("${BASE_TF_DIR}/infra" "${BASE_TF_DIR}/cluster" "${BASE_TF_DIR}/nodes")
SH_DIR="$(cd "$(dirname "$${BASH_SOURCE[0]}")" && pwd)"
ROOT_MOD_SOURCE="./../.."
INFRA_DIR="${SH_DIR}/${BASE_TF_DIR}/infra"

deploy() {
  [ -f "${SH_DIR}/domino.pem" ] || ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f "${SH_DIR}/domino.pem"

  for dir in "${MOD_DIRS[@]}"; do
    echo "Running terraform apply in ${dir}"
    terraform -chdir="${SH_DIR}/${dir}" init
    terraform -chdir="${SH_DIR}/${dir}" validate
    terraform -chdir="${SH_DIR}/${dir}" apply -state="${SH_DIR}/${dir}.tfstate" --auto-approve --input=false
    terraform -chdir="${SH_DIR}/${dir}" apply -state="${SH_DIR}/${dir}.tfstate" --refresh-only --auto-approve --input=false
  done
}

install_helm() {
  if [ -z "$HELM_VERSION" ]; then
    echo "HELM_VERSION environment variable not set, exiting."
    exit 1
  fi
  echo "Installing Helm version: ${HELM_VERSION}"
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod +x get_helm.sh
  ./get_helm.sh --version "${HELM_VERSION}"
  rm ./get_helm.sh
  helm version --short
}

install_hcledit() {
  hcledit_version="${HCLEDIT_VERSION}"
  hcledit_artifact=hcledit_${hcledit_version}_linux_amd64.tar.gz
  curl -fsSL -o "${hcledit_artifact}" "https://github.com/minamijoyo/hcledit/releases/download/v${hcledit_version}/${hcledit_artifact}"
  tar xvzf "${hcledit_artifact}"
  sudo mv hcledit /usr/local/bin/ && rm "${hcledit_artifact}" && hcledit version
}

set_tf_vars() {
  envsubst <"${INFRA_DIR}/ci.tfvars.tftpl" | tee "${INFRA_DIR}/terraform.tfvars"
}

destroy() {
  local len dir
  len=${#MOD_DIRS[@]}

  for ((i = (len - 1); i >= 0; i--)); do
    dir="${MOD_DIRS[$i]}"
    echo "Running terraform destroy in ${dir}"
    terraform -chdir="${SH_DIR}/${dir}" destroy -state="${SH_DIR}/${dir}.tfstate" --auto-approve --input=false || terraform -chdir="${SH_DIR}/${dir}" -state="${SH_DIR}/${BASE_TF_DIR}/${dir}.tfstate" destroy --refresh=false --auto-approve --input=false
  done
}

set_mod_src_local() {
  echo "Updating module source to local."

  for dir in "${MOD_DIRS[@]}"; do
    if [ "$dir" != "infra" ]; then
      MOD_SOURCE="${ROOT_MOD_SOURCE}/submodules/${dir}"
    else
      MOD_SOURCE="${ROOT_MOD_SOURCE}"
    fi
    echo "Setting module source to local ref: ${MOD_SOURCE} on ${dir}"
    hcledit attribute set "module.${dir}.source" "\"${MOD_SOURCE}\"" -u -f "${dir}/main.tf"
  done
}

set_mod_src_latest_rel() {
  echo "Updating module source to the latest published release."

  latest_release_tag="$(curl -s https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/latest | jq -r .tag_name)"
  echo "Latest published release tag is: ${latest_release_tag}"
  ROOT_MOD_SOURCE="github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git?ref=${latest_release_tag}"
  MAJOR_MOD_VERSION=$(echo "${latest_release_tag}" | awk -F'.' '{print $1}' | sed 's/^v//')
  echo "export MAJOR_MOD_VERSION=$MAJOR_MOD_VERSION" >>$BASH_ENV

  if (($MAJOR_MOD_VERSION < 3)); then
    echo "Setting module source to: ${ROOT_MOD_SOURCE}"
    cat <<<$(jq --arg mod_source "${ROOT_MOD_SOURCE}" '.module[0].domino_eks.source = $mod_source' main.tf.json) >main.tf.json
  else
    for dir in "${MOD_DIRS[@]}"; do
      MOD_SOURCE="github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git//modules/${dir}?ref=${latest_release_tag}"

      echo "Setting module source to local ref: ${MOD_SOURCE} on ${dir}"
      hcledit attribute set "module.${dir}.source" "\"${MOD_SOURCE}\"" -u -f "${dir}/main.tf"
      cat "${dir}/main.tf"
    done
  fi

}

for arg in "$@"; do
  "$arg"
done
