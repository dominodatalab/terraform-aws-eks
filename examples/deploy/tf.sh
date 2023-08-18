#!/usr/bin/env bash
set -euo pipefail

SH_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_TF_DIR="${SH_DIR}/terraform"

declare -a MOD_DIRS=(
  "${BASE_TF_DIR}/infra"
  "${BASE_TF_DIR}/cluster"
  "${BASE_TF_DIR}/nodes"
)

state_exists() {
  local dir=$1
  local name=$(basename $dir)
  local state_path="${BASE_TF_DIR}/${name}.tfstate"
  [[ -f $state_path && -s $state_path ]]
}

has_resources() {
  local dir=$1
  local name=$(basename $dir)
  local state_path="${BASE_TF_DIR}/${name}.tfstate"

  if [[ ! -f "$state_path" ]]; then
    return 1
  fi
  local resource_count=$(jq '.resources | length' "$state_path")
  [[ $resource_count -gt 0 ]]
}

check_dependencies() {
  local name=$1
  if [[ $name == "cluster" ]]; then
    if ! has_resources "${BASE_TF_DIR}/infra"; then
      echo "Cannot plan/apply 'cluster' without 'infra' being provisioned."
      exit 1
    fi
  elif [[ $name == "nodes" ]]; then
    if ! has_resources "${BASE_TF_DIR}/infra" || ! has_resources "${BASE_TF_DIR}/cluster"; then
      echo "Cannot plan/apply 'nodes' without 'infra' and 'cluster' being provisioned."
      exit 1
    fi
  fi
  return 0
}

run_tf_command() {
  local dir="$1"
  local cmd="$2"

  local name=$(basename "$dir")
  local state_path="${BASE_TF_DIR}/${name}.tfstate"

  case $cmd in
  init)
    terraform -chdir="$dir" init
    ;;
  plan)
    check_dependencies $name
    terraform -chdir="$dir" plan -input=false -state="$state_path" -var-file="${BASE_TF_DIR}/${name}.tfvars"
    ;;
  apply)
    check_dependencies $name
    terraform -chdir="$dir" apply -input=false -state="$state_path" -var-file="${BASE_TF_DIR}/${name}.tfvars" -auto-approve
    ;;
  refresh)
    check_dependencies $name
    terraform -chdir="$dir" apply -input=false -state="$state_path" -var-file="${BASE_TF_DIR}/${name}.tfvars" -refresh-only -auto-approve
    ;;
  validate)
    terraform -chdir="$dir" validate
    ;;
  output)
    if state_exists "$dir"; then
      terraform -chdir="$dir" output -state="$state_path" | tee "${BASE_TF_DIR}/${name}.outputs"
    else
      echo "No state found for $name"
    fi
    ;;
  destroy)
    if state_exists "$dir" && has_resources "$dir"; then
      terraform -chdir="$dir" destroy -input=false -state="$state_path" -var-file="${BASE_TF_DIR}/${name}.tfvars" -auto-approve || terraform -chdir="$dir" destroy -input=false -state="$state_path" -var-file="${BASE_TF_DIR}/${name}.tfvars" -auto-approve -refresh=false
    else
      echo "Nothing to destroy for $name"
    fi
    ;;
  *)
    echo "Unsupported command: $cmd"
    exit 1
    ;;
  esac
}

if [[ "$#" -ne 2 ]]; then
  echo "Usage: ./tf.sh <command> <component>"
  echo "Supported commands: init, plan, apply, destroy, output"
  echo "Components: infra, cluster, nodes, all"
  exit 1
fi

command=$1
component=$2

case $component in
infra)
  run_tf_command "${BASE_TF_DIR}/infra" "$command"
  ;;
cluster)
  run_tf_command "${BASE_TF_DIR}/cluster" "$command"
  ;;
nodes)
  run_tf_command "${BASE_TF_DIR}/nodes" "$command"
  ;;
all)
  if [[ "$command" == "destroy" ]]; then
    for ((idx = ${#MOD_DIRS[@]} - 1; idx >= 0; idx--)); do
      run_tf_command "${MOD_DIRS[idx]}" "$command"
    done
  else
    for dir in "${MOD_DIRS[@]}"; do
      run_tf_command "$dir" "$command"
    done
  fi
  ;;
*)
  echo "Unknown component: $component"
  echo "Available components: infra, cluster, nodes, all"
  exit 1
  ;;
esac
