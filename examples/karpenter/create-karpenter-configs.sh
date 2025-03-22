#!/bin/bash

set -e

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

nodeclasses_dir="${SH_DIR}/nodeclasses"
nodepools_dir="${SH_DIR}/nodepools"

check_directories() {
  if [ ! -d "$nodeclasses_dir" ]; then
    echo "Error: nodeclasses directory not found"
    echo "Please run this script from the karpenter directory"
    exit 1
  fi

  if [ ! -d "$nodepools_dir" ]; then
    echo "Error: nodepools directory not found"
    echo "Please run this script from the karpenter directory"
    exit 1
  fi

  if ! ls "$nodeclasses_dir"/*.yaml 1>/dev/null 2>&1; then
    echo "Error: No YAML files found in nodeclasses directory"
    echo "Please ensure there are .yaml files in the nodeclasses directory"
    exit 1
  fi

  if ! ls "$nodepools_dir"/*.yaml 1>/dev/null 2>&1; then
    echo "Error: No YAML files found in nodepools directory"
    echo "Please ensure there are .yaml files in the nodepools directory"
    exit 1
  fi
}

apply_nodeclasses() {
  echo "Applying nodeclasses..."
  for file in "$nodeclasses_dir"/*.yaml; do
    echo "Applying $file..."
    kubectl apply -f "$file"
  done
}

apply_nodepools() {
  echo "Applying nodepools..."
  for file in "$nodepools_dir"/*.yaml; do
    echo "Applying $file..."
    kubectl apply -f "$file"
  done
}

echo "Applying Karpenter configurations..."

check_directories

apply_nodeclasses
apply_nodepools

echo "All Karpenter configurations applied successfully!"
