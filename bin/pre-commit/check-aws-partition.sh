#!/usr/bin/env bash

exec 1>&2

check_aws_partition() {
  declare -A failed_files
  exclude_patterns=("policy/AWSLambdaExecute")
  exclude_files=("README.md")

  for file in "$@"; do
    skip_file=false
    for exclude in "${exclude_files[@]}"; do
      if [[ "$file" == "$exclude" ]]; then
        skip_file=true
        break
      fi
    done

    if [ "$skip_file" = true ]; then
      continue
    fi

    if grep -q "arn:aws" "${file}"; then
      skip_file=false
      for pattern in "${exclude_patterns[@]}"; do
        if grep -q "$pattern" "${file}"; then
          skip_file=true
          break
        fi
      done

      if [ "$skip_file" = false ]; then
        failed_files["${file}"]=1
      fi
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
