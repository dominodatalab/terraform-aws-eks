#! /usr/bin/env bash

exec 1>&2

check_aws_partition() {
  declare -A failed_files

  for file in "$@"; do
    if grep -q "arn:aws" "${file}"; then
      failed_files["${file}"]=1
    fi
  done

  if [ ${#failed_files[@]} -ne 0 ]; then
    for file in "${!failed_files[@]}"; do
      echo "${file} contains a hardcoded AWS partition. Use arn:\${data.aws_partition.current.partition} instead of arn:aws."
    done
    return 1
  fi

  return 0

}

check_aws_partition "$@"
exit_code=$?
exit $exit_code
