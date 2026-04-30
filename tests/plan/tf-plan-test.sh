#! /usr/bin/env bash

test_file_name="${1:-none}"

TFVARS_BASE_PATH="../../examples/tfvars/"
SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
exclude=("bring-your-vpc.tfvars" "kms-byok.tfvars" "private-link.tfvars" "oidc-byo.tfvars" "nodes-custom-ami.tfvars")

failed_vars=()
success_vars=()

verify_terraform() {
  if ! [ -x "$(command -v terraform)" ]; then
    printf "\n\033[0;31mError: Terraform is not installed!!!\033[0m\n"
    exit 1
  else
    terraform_version=$(terraform --version | awk '/Terraform/ {print $2}' | awk -F 'version' '{print $1}' | tr -d '[:space:]')
    printf "\033[0;32mTerraform version: ${terraform_version} is installed.\033[0m\n"
  fi
}

verify_aws_creds() {
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    printf "\033[0;31mERROR: AWS credentials are wrong or not set.\033[0m\n"
    exit 1
  fi
}

PLAN_LOGS_DIR="${PLAN_LOGS_DIR:-/tmp/tf-plan-logs}"
mkdir -p "$PLAN_LOGS_DIR"

tf_plan() {
  local tfvars="$1"
  local test_pem="terraform/plan-test.pem"
  local base
  base="$(basename "$tfvars")"
  local plan_log="$PLAN_LOGS_DIR/${base}.log"

  printf "\n\033[0;33mRunning terraform plan for ${tfvars}\033[0m:\n"
  if [ ! -f "$test_pem" ]; then
    ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f "$test_pem" && chmod 400 "$test_pem"
  fi

  terraform -chdir=terraform init -upgrade
  terraform -chdir=terraform plan -var-file="$tfvars" -var "ssh_pvt_key_path=$(basename $test_pem)" 2>&1 | tee "$plan_log"
  local rc=${PIPESTATUS[0]}

  if [ "$rc" != "0" ]; then
    printf "\033[0;31mERROR: terraform plan failed for $tfvars\033[0m.\n"
    failed_vars+=("$base")
  else
    printf "\033[0;32mSUCCESS: terraform plan succeeded for $tfvars\033[0m.\n"
    success_vars+=("$base")
  fi
}

run_terraform_plans() {

  if [ "$test_file_name" == "none" ]; then
    for tfvars in "${TFVARS_BASE_PATH}"/*.tfvars; do
      base_tfvars=$(basename "$tfvars")
      skip=false

      for excl in "${exclude[@]}"; do
        if [[ "$base_tfvars" == *"$excl" ]]; then
          skip=true
          break
        fi
      done

      $skip && continue
      tf_plan "$(realpath $tfvars)"
    done
  else
    tf_plan "$(realpath "${TFVARS_BASE_PATH}/${test_file_name}.tfvars")"
  fi
}

create_kms_key() {
  local dir="create-kms-key"

  printf "\n\033[0;33mCreating KMS key\033[0m\n"
  terraform -chdir="$dir" init
  if ! terraform -chdir="$dir" apply --auto-approve; then
    printf "\n\033[0;31mFailed to create kms key!!!\033[0m\n"
    failed_vars+=("kms")
  else
    printf "\n\033[0;32mKMS key created successfully\033[0m\n"
  fi
  KMS_KEY_ID="$(terraform -chdir="$dir" output -raw kms_key_id)"
  export KMS_KEY_ID
}

destroy_kms_key() {
  local dir="create-kms-key"

  printf "\n\033[0;33mDestroying KMS key\033[0m\n"
  terraform -chdir="$dir" destroy --auto-approve || terraform -chdir="$dir" destroy --auto-approve --refresh=false
}

test_byok_kms() {
  create_kms_key
  if test -z $KMS_KEY_ID; then
    printf "\033[0;31mERROR Obtaining KMS_KEY_ID \033[0m.\n"
    exit 1
  fi

  local KMS_VARS_FILE="../../examples/tfvars/kms-byok.tfvars"
  local vars_file="$(basename $KMS_VARS_FILE)"

  cat $KMS_VARS_FILE | sed "s/key_id = \".*\"/key_id = \"$KMS_KEY_ID\"/" | tee "$vars_file"

  tf_plan "$(realpath $vars_file)" && rm "$vars_file"
}

# The example nodes-custom-ami.tfvars has hardcoded AMI IDs for illustration,
# but AWS deregisters EKS-optimized AMIs over time which breaks the plan.
# Resolve current AL2023 AMIs from SSM and substitute before planning.
test_nodes_custom_ami() {
  local NODES_VARS_FILE="../../examples/tfvars/nodes-custom-ami.tfvars"
  local vars_file
  vars_file="$(basename "$NODES_VARS_FILE")"
  local k8s_version
  k8s_version=$(awk -F'"' '/k8s_version[[:space:]]*=/{print $2; exit}' "$NODES_VARS_FILE")

  printf "\n\033[0;33mResolving AL2023 AMIs for k8s %s\033[0m\n" "$k8s_version"
  local standard_ami nvidia_ami
  standard_ami=$(aws ssm get-parameter --region us-west-2 \
    --name "/aws/service/eks/optimized-ami/${k8s_version}/amazon-linux-2023/x86_64/standard/recommended/image_id" \
    --query 'Parameter.Value' --output text 2>/dev/null)
  nvidia_ami=$(aws ssm get-parameter --region us-west-2 \
    --name "/aws/service/eks/optimized-ami/${k8s_version}/amazon-linux-2023/x86_64/nvidia/recommended/image_id" \
    --query 'Parameter.Value' --output text 2>/dev/null)

  if [[ -z "$standard_ami" || "$standard_ami" == "None" || -z "$nvidia_ami" || "$nvidia_ami" == "None" ]]; then
    printf "\033[0;31mERROR: Failed to resolve AL2023 AMIs from SSM for k8s %s\033[0m\n" "$k8s_version"
    failed_vars+=("$vars_file")
    return
  fi
  printf "\033[0;32mStandard AMI: %s | NVIDIA AMI: %s\033[0m\n" "$standard_ami" "$nvidia_ami"

  # The example file has two unique AMI IDs: one shared by compute+platform
  # (standard) and one for gpu (nvidia). Substitute by original ID to preserve
  # structure regardless of which specific IDs are in the file.
  mapfile -t orig_amis < <(grep -oE 'ami-[0-9a-f]+' "$NODES_VARS_FILE" | awk '!seen[$0]++')
  if [ "${#orig_amis[@]}" -ne 2 ]; then
    printf "\033[0;31mERROR: Expected 2 distinct AMI IDs in %s, found %d\033[0m\n" "$NODES_VARS_FILE" "${#orig_amis[@]}"
    failed_vars+=("$vars_file")
    return
  fi

  sed -e "s|${orig_amis[0]}|${standard_ami}|g" \
      -e "s|${orig_amis[1]}|${nvidia_ami}|g" \
      "$NODES_VARS_FILE" > "$vars_file"

  tf_plan "$(realpath $vars_file)" && rm "$vars_file"
}

finish() {
  destroy_kms_key

  if [ "${#success_vars[@]}" != "0" ]; then
    printf "\n\033[0;32mThe following examples ran a terraform plan successfully:\033[0m\n"
    printf '\033[0;32m%s\n\033[0m' "${success_vars[@]}"
  fi

  if [ "${#failed_vars[@]}" != "0" ]; then
    printf "\n\033[0;31mThe following examples failed to run a terraform plan:\033[0m\n"
    printf '\033[0;31m%s\n\033[0m' "${failed_vars[@]} "
    for failed in "${failed_vars[@]}"; do
      local log="$PLAN_LOGS_DIR/${failed}.log"
      if [ -f "$log" ]; then
        printf "\n\033[0;31m----- Tail of %s (last 200 lines) -----\033[0m\n" "$failed"
        tail -n 200 "$log"
        printf "\033[0;31m----- End of %s tail -----\033[0m\n" "$failed"
      fi
    done
    exit 1
  fi
}

trap finish EXIT ERR INT TERM
verify_terraform
verify_aws_creds
run_terraform_plans
if [ "$test_file_name" == "none" ]; then
  test_byok_kms
  test_nodes_custom_ami
fi
