#!/usr/bin/env bash
set -euo pipefail

declare -a MOD_DIRS=('infra' 'eks' 'nodes')
SH_DIR="$(cd "$(dirname "$${BASH_SOURCE[0]}")" && pwd)"

deploy() {
  local INFRA_DIR="${SH_DIR}/infra"
  [ -f "${SH_DIR}/domino.pem" ] || ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f "${SH_DIR}/domino.pem"

  for dir in "${MOD_DIRS[@]}"; do
    echo "Running terraform apply in ${dir}"
    terraform -chdir="${SH_DIR}/${dir}" init
    terraform -chdir="${SH_DIR}/${dir}" validate
    terraform -chdir="${SH_DIR}/${dir}" apply --auto-approve --input=false
    terraform -chdir="${SH_DIR}/${dir}" apply --refresh-only --auto-approve --input=false
  done
}

destroy() {
  local len dir
  len=${#MOD_DIRS[@]}

  for ((i = (len - 1); i >= 0; i--)); do
    dir="${MOD_DIRS[$i]}"
    echo "Running terraform destroy in ${dir}"
    terraform -chdir="${SH_DIR}/${dir}" destroy --auto-approve --input=false || terraform -chdir="${SH_DIR}/${dir}" destroy --refresh=false --auto-approve --input=false
  done
}

if [[ "${1}" == "deploy" ]]; then
  deploy
elif [[ "${1}" == "destroy" ]]; then
  destroy
else
  echo "Invalid option. Usage: deploy.sh [deploy|destroy]"
  exit 1
fi
