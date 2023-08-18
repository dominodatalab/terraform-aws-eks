#! /usr/bin/env bash

exclude=("bring-your-vpc.tfvars" "kms.tfvars")

failed_vars=()
success_vars=()

verify_terraform() {
  if ! [ -x "$(command -v terraform)" ]; then
    printf "\n\033[0;31mError: Terraform is not installed!!!\033[0m\n"
    exit 1
  else
    terraform_version=$(terraform --version | awk '/Terraform/ {print $2}')
    printf "\033[0;32mTerraform version $terraform_version is installed.\033[0m\n"
  fi
}

verify_aws_creds() {
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    printf "\033[0;31mERROR: AWS credentials are wrong or not set.\033[0m\n"
    exit 1
  fi
}

tf_plan() {
  local tfvars="${1}"
  terraform -chdir=terraform init
  terraform -chdir=terraform plan -var-file=./../../../examples/tfvars/${tfvars} -var "ssh_pvt_key_path=plan-test.pem"

  if [ "$?" != "0" ]; then
    printf "\033[0;31mERROR: terraform plan failed for $tfvars\033[0m.\n"
    failed_vars+=("${tfvars}")
  else
    printf "\033[0;32mSUCCESS: terraform plan succeeded for $tfvars\033[0m.\n"
    success_vars+=("${tfvars}")
  fi

}

run_terraform_plans() {
  for tfvars in ../../examples/tfvars/*.tfvars; do
    base_tfvars=$(basename "$tfvars")
    skip=false

    for excl in "${exclude[@]}"; do
      if [[ "$base_tfvars" == *"$excl" ]]; then
        skip=true
        break
      fi
    done

    $skip && continue

    printf "\n\033[0;33mRunning terraform plan for ${base_tfvars}\033[0m:\n"
    tf_plan "${base_tfvars}"
  done

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
  export KMS_KEY_ID="$(terraform -chdir="$dir" output kms_key_id)"
}

destroy_kms_key() {
  local dir="create-kms-key"

  printf "\n\033[0;33mDestroying KMS key\033[0m\n"
  terraform -chdir="$dir" destroy --auto-approve || terraform -chdir="$dir" destroy --auto-approve --refresh=false
}

test_kms() {
  KMS_KEY_ID=""
  create_kms_key
  if test -z $KMS_KEY_ID; then
    printf "\033[0;31mERROR Obtaining KMS_KEY_ID \033[0m.\n"
    exit 1
  fi
  temp_file=$(mktemp)
  KMS_VARS_FILE="../../examples/tfvars/kms.tfvars"
  envsubst <"${KMS_VARS_FILE}" >"$temp_file" && mv "$temp_file" "${KMS_VARS_FILE}"

  tf_plan "$(basename ${KMS_VARS_FILE})"
}

finish() {
  destroy_kms_key

  if [ "${#success_vars[@]}" != "0" ]; then
    printf "\n\033[0;32mThe following examples ran the terraform plan successfully:\033[0m\n"
    printf '\033[0;32m%s\n\033[0m' "${success_vars[@]}"
  fi

  if [ "${#failed_vars[@]}" != "0" ]; then
    printf "\n\033[0;31mThe following examples failed the terraform plan:\033[0m\n"
    printf '\033[0;31m%s\n\033[0m' "${failed_vars[@]} "
    exit 1
  fi
}

trap finish EXIT ERR INT TERM
verify_terraform
verify_aws_creds
run_terraform_plans
test_kms
