#! /usr/bin/env bash

test_file_name="${1:-none}"

TFVARS_BASE_PATH="../../examples/tfvars/"
SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
exclude=("bring-your-vpc.tfvars" "kms-byok.tfvars" "private-link.tfvars" "oidc-byo.tfvars")

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

tf_plan() {
  local tfvars="$1"
  local test_pem="terraform/plan-test.pem"

  printf "\n\033[0;33mRunning terraform plan for ${tfvars}\033[0m:\n"
  if [ ! -f "$test_pem" ]; then
    ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f "$test_pem" && chmod 400 "$test_pem"
  fi

  terraform -chdir=terraform init -upgrade
  terraform -chdir=terraform plan -var-file="$tfvars" -var "ssh_pvt_key_path=$(basename $test_pem)"

  if [ "$?" != "0" ]; then
    printf "\033[0;31mERROR: terraform plan failed for $tfvars\033[0m.\n"
    failed_vars+=("$(basename $tfvars)")
  else
    printf "\033[0;32mSUCCESS: terraform plan succeeded for $tfvars\033[0m.\n"
    success_vars+=("$(basename $tfvars)")
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

create_eks_oidc_provider() {
  local dir="create-oidc-provider"

  eval $(tfvar --var-file ../../examples/tfvars/oidc-byo.tfvars --env-var ./terraform | grep -E 'region|deploy_id')

  printf "\n\033[0;33mCreating OIDC provider\033[0m\n"
  terraform -chdir="$dir" init
  if ! terraform -chdir="$dir" apply --auto-approve; then
    printf "\n\033[0;31mFailed to create OIDC provider!!!\033[0m\n"
    failed_vars+=("kms")
  else
    printf "\n\033[0;32mOIDC provider created successfully\033[0m\n"
  fi

  OIDC_INFO_VARS_FILE="${SH_DIR}/oidc.json"
  terraform -chdir="$dir" output -json | jq -r '.eks_oidc_provider.value' >"$OIDC_INFO_VARS_FILE"

  export OIDC_INFO_VARS_FILE
}

destroy_eks_oidc_provider() {
  local dir="create-oidc-provider"

  printf "\n\033[0;33mDestroying OIDC provider\033[0m\n"
  terraform -chdir="$dir" destroy --auto-approve || terraform -chdir="$dir" destroy --auto-approve --refresh=false
}

test_byo_eks_oidc_provider() {
  create_eks_oidc_provider
  if test -z $OIDC_INFO_VARS_FILE; then
    printf "\033[0;31mERROR Obtaining OIDC_INFO_VARS_FILE \033[0m.\n"
    exit 1
  fi

  local OIDC_VARS_FILE="../../examples/tfvars/oidc-byo.tfvars"
  local vars_file="$(basename $OIDC_VARS_FILE)"
  local TEST_VARS_FILE="${SH_DIR}/test-${vars_file}"

  tfvar ./terraform --var-file "$OIDC_VARS_FILE" --var-file "$OIDC_INFO_VARS_FILE" >"$TEST_VARS_FILE"

  cat "$TEST_VARS_FILE"

  tf_plan "$TEST_VARS_FILE" && rm "$TEST_VARS_FILE"
}

finish() {
  destroy_eks_oidc_provider
  destroy_kms_key

  if [ "${#success_vars[@]}" != "0" ]; then
    printf "\n\033[0;32mThe following examples ran a terraform plan successfully:\033[0m\n"
    printf '\033[0;32m%s\n\033[0m' "${success_vars[@]}"
  fi

  if [ "${#failed_vars[@]}" != "0" ]; then
    printf "\n\033[0;31mThe following examples failed to run a terraform plan:\033[0m\n"
    printf '\033[0;31m%s\n\033[0m' "${failed_vars[@]} "
    exit 1
  fi
}

trap finish EXIT ERR INT TERM
verify_terraform
verify_aws_creds
run_terraform_plans
[ "$test_file_name" == "none" ] && {
  test_byok_kms
  test_byo_eks_oidc_provider
}
