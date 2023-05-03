#! /usr/bin/env bash

exclude=("bring-your-vpc" "examples.pem" "tf-plan-test.sh" "create-kms-key" "kms")

failed_dirs=()
success_dirs=()

verify_terraform() {
  if ! [ -x "$(command -v terraform)" ]; then
    printf "\n\033[0;31mError: Terraform is not installed!!!\033[0m\n"
    exit 1
  else
    terraform_version=$(terraform --version | awk '/Terraform/ {print $2}')
    printf "\033[0;32mTerraform version $terraform_version is installed.\033[0m\n"
  fi
}

tf_plan() {
  local dir="${1}"
  terraform -chdir="$dir" init
  terraform -chdir="$dir" plan

  if [ "$?" != "0" ]; then
    printf "\033[0;31mERROR: terraform plan failed in $dir\033[0m.\n"
    failed_dirs+=("${dir%/}")
  else
    printf "\033[0;32mSUCCESS: terraform plan succeeded in $dir\033[0m.\n"
    success_dirs+=("${dir%/}")
  fi

}

run_terraform_plans() {
  for dir in */; do
    [[ " ${exclude[*]} " == *" ${dir%/} "* ]] && continue
    printf "\n\033[0;33mRunning terraform plan in ${dir%/}\033[0m:\n"
    tf_plan "${dir}"
  done
}

create_kms_key() {
  local dir="create-kms-key"

  printf "\n\033[0;33mCreating KMS key\033[0m\n"
  terraform -chdir="$dir" init
  if ! terraform -chdir="$dir" apply --auto-approve; then
    printf "\n\033[0;31mFailed to create kms key!!!\033[0m\n"
    failed_dirs+=("kms")
  else
    printf "\n\033[0;32mKMS key created successfully\033[0m\n"
  fi

}

destroy_kms_key() {
  local dir="create-kms-key"

  printf "\n\033[0;33mDestroying KMS key\033[0m\n"
  terraform -chdir="$dir" destroy --auto-approve || terraform -chdir="$dir" destroy --auto-approve --refresh=false
}

test_kms() {
  create_kms_key
  tf_plan "kms"
}

finish() {
  destroy_kms_key

  if [ "${#success_dirs[@]}" != "0" ]; then
    printf "\n\033[0;32mThe following examples ran the terraform plan successfully:\033[0m\n"
    printf '\033[0;32m%s\n\033[0m' "${success_dirs[@]}"
  fi

  if [ "${#failed_dirs[@]}" != "0" ]; then
    printf "\n\033[0;31mThe following examples failed the terraform plan:\033[0m\n"
    printf '\033[0;31m%s\n\033[0m' "${failed_dirs[@]} "
    exit 1
  fi
}

trap finish EXIT ERR INT TERM
verify_terraform
run_terraform_plans
test_kms
