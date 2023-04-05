#! /usr/bin/env bash

exclude=("bring-your-vpc" "examples.pem" "tf-plan-test.sh")

failed_dirs=()
success_dirs=()

verify_terraform() {
  if ! [ -x "$(command -v terraform)" ]; then
    echo "Error: Terraform is not installed."
    exit 1
  else
    terraform_version=$(terraform --version | awk '/Terraform/ {print $2}')
    echo "Terraform version $terraform_version is installed."
  fi
}

run_terraform_plans() {
  for dir in */; do
    [[ " ${exclude[*]} " == *" ${dir%/} "* ]] && continue
    printf "\n\033[0;33mRunning terraform plan in $dir\033[0m:\n"

    terraform -chdir="$dir" init
    terraform -chdir="$dir" plan

    if [ "$?" != "0" ]; then
      printf "\033[0;31mERROR: terraform plan failed in $dir\033[0m.\n"
      failed_dirs+=("$dir")
    else
      printf "\033[0;32mSUCCESS: terraform plan succeeded in $dir\033[0m.\n"
      success_dirs+=("$dir")
    fi
  done

  if [ "${#failed_dirs[@]}" != "0" ]; then
    printf "\n\033[0;31mThe following examples failed the terraform plan:\033[0m\n"
    printf '\033[0;31m%s\n\033[0m' "${failed_dirs[@]} "
    exit 1
  fi

  if [ "${#success_dirs[@]}" != "0" ]; then
    printf "\n\033[0;32mThe following examples ran the terraform plan successfully:\033[0m\n"
    printf '\033[0;32m%s\n\033[0m' "${success_dirs[@]}"
  fi
}

verify_terraform
run_terraform_plans
