#!/usr/bin/env bash
set -euo pipefail

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
source "${SH_DIR}/meta.sh"

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
      printf "\nERROR: Cannot plan/apply 'cluster' without 'infra' being provisioned !!!\n\n"
      exit 1
    fi
  elif [[ $name == "nodes" ]]; then
    if ! has_resources "${BASE_TF_DIR}/infra" || ! has_resources "${BASE_TF_DIR}/cluster"; then
      printf "\nERROR: Cannot plan/apply 'nodes' without 'infra' and 'cluster' being provisioned. being provisioned !!!\n\n"
      exit 1
    fi
  fi
  return 0
}

run_tf_command() {
  local dir="$1"
  local cmd="$2"

  if [[ "$#" == 3 ]]; then
    local param=$3
  else
    local param='false'
  fi

  local name=$(basename "$dir")

  local plan_path="${BASE_TF_DIR}/${name}-terraform.plan"
  local state_path="${BASE_TF_DIR}/${name}.tfstate"

  local tfvars_file="${BASE_TF_DIR}/${name}.tfvars"
  local tfvars_json_file="${tfvars_file}.json"

  # Skip .tfvars check for init and output commands
  if [[ $cmd != "init" && $cmd != "output" ]]; then
    if [[ -f "$tfvars_file" && -f "$tfvars_json_file" ]]; then
      echo "ERROR: Both ${tfvars_file} and ${tfvars_json_file} exist. Please consolidate variables onto one of them and remove the other."
      exit 1
    fi

    if [[ -s "$tfvars_json_file" ]]; then
      tfvars_file="$tfvars_json_file"
    fi

    if [[ ! -s "$tfvars_file" ]]; then
      echo "ERROR: Neither ${tfvars_file} nor ${tfvars_json_file} exists or they are empty."
      exit 1
    fi
  fi

  update_node_groups() {
    echo "Updating EKS Node Pools"
    mapfile -t node_pools < <(terraform -chdir="$dir" state list -state="$state_path" | grep 'aws_eks_node_group.node_groups')

    if [[ ${#node_pools[@]} -eq 0 ]]; then
      echo "Error: No node pools found to update."
      exit 1
    fi

    printf "Updating the following node_groups one at a time...\n%s\n" "${node_pools[@]}"
    for np in "${node_pools[@]}"; do
      echo "Updating $np"
      terraform apply --target "$np" --auto-approve
    done
  }

  case $cmd in
  init)
    terraform -chdir="$dir" init
    ;;
  plan)
    check_dependencies $name
    terraform -chdir="$dir" plan -input=false -state="$state_path" -var-file="$tfvars_file"
    ;;
  plan_out)
    check_dependencies $name
    terraform -chdir="$dir" plan -input=false -state="$state_path" -var-file="$tfvars_file" -out="$plan_path"
    echo "Terraform plan for $name saved at: $(realpath $plan_path)"
    ;;
  apply)
    check_dependencies $name
    terraform -chdir="$dir" apply -input=false -state="$state_path" -var-file="$tfvars_file" -auto-approve
    ;;
  apply_plan)
    check_dependencies $name
    if [ ! -f "$plan_path" ]; then
      echo "$plan_path does not exist. Exiting..."
      exit 1
    fi
    terraform -chdir="$dir" apply -input=false -state="$state_path" -auto-approve "$plan_path"
    ;;
  refresh)
    check_dependencies $name
    terraform -chdir="$dir" apply -input=false -state="$state_path" -var-file="$tfvars_file" -refresh-only -auto-approve
    ;;
  show_plan_json)
    check_dependencies $name
    terraform -chdir="$dir" show -json "$plan_path"
    ;;
  validate)
    terraform -chdir="$dir" validate
    ;;
  output)
    if state_exists "$dir"; then
      if [ $param != "false" ]; then
        terraform -chdir="$dir" output -state="$state_path" "$param"
      else
        terraform -chdir="$dir" output -state="$state_path" | tee "${BASE_TF_DIR}/${name}.outputs"
      fi
    else
      echo "No state found for $name"
    fi
    ;;
  roll_nodes)
    if [[ $dir != "nodes" ]]; then
      echo "Invalid component: ${dir} .The 'roll_nodes' command is only applicable to 'nodes'"
      exit 1
    fi
    update_node_groups
    ;;
  destroy)
    if state_exists "$dir" && has_resources "$dir"; then
      terraform -chdir="$dir" destroy -input=false -state="$state_path" -var-file="$tfvars_file" -auto-approve || terraform -chdir="$dir" destroy -input=false -state="$state_path" -var-file="$tfvars_file" -auto-approve -refresh=false
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

component=$1
command=$2

if [[ "$#" == 3 ]]; then
  param=$3
else
  param='false'
fi

if [[ "$command" != "output" ]] && [[ "$#" -ne 2 ]]; then
  echo "Usage: ./tf.sh <component> <command>"

  echo -e "\nComponents:"
  echo -e "  infra    \tManage the infrastructure components."
  echo -e "  cluster  \tManage the cluster components."
  echo -e "  nodes    \tManage the node components."
  echo -e "  all      \tManage all components."
  echo "Note: If an unlisted component is provided, the script will attempt to execute the given command, assuming the corresponding directory is properly configured."

  echo -e "\nCommands:"
  echo -e "  init     \t\tInitialize the working directory."
  echo -e "  validate \t\tCheck the syntax and validate the configuration."
  echo -e "  plan     \t\tGenerate an execution plan."
  echo -e "  plan_out \t\tGenerate a plan and save it to a file."
  echo -e "  apply    \t\tExecute the actions proposed in the Terraform plan."
  echo -e "  refresh  \t\tUpdate local state with remote resources."
  echo -e "  destroy  \t\tDestroy the Terraform-managed infrastructure."
  echo -e "  output   \t\tDisplay outputs from the Terraform state."
  echo -e "  output <param> \tDisplay a specific output."

  exit 1
fi

case $component in
infra | cluster | nodes)
  if [[ "$param" != "false" ]]; then
    run_tf_command "${BASE_TF_DIR}/${component}" "$command" "$param"
  else
    run_tf_command "${BASE_TF_DIR}/${component}" "$command"
  fi
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
  echo "Default components: infra, cluster, nodes, all"
  if [[ -d "${BASE_TF_DIR}/${component}" ]]; then
    if ls "${BASE_TF_DIR}/${component}"/*.tf 1>/dev/null 2>&1; then
      echo "Running command $command on non-default component: $component"
      echo "Note: Component: all does not include $component"
      run_tf_command "${BASE_TF_DIR}/${component}" "$command"
    else
      echo "Directory exists but no .tf files found in ${BASE_TF_DIR}/${component}"
      exit 1
    fi
  else
    echo "Component: $component Not supported."
    exit 1
  fi
  ;;
esac
