#!/usr/bin/env bash

BASE_TF_DIR="${DEPLOY_DIR}/terraform"
declare -a MOD_DIRS=(
  "${BASE_TF_DIR}/infra"
  "${BASE_TF_DIR}/cluster"
  "${BASE_TF_DIR}/nodes"
)

INFRA_DIR="${MOD_DIRS[0]}"
CLUSTER_DIR="${MOD_DIRS[1]}"
NODES_DIR="${MOD_DIRS[2]}"

CLUSTER_STATE="${BASE_TF_DIR}/cluster.tfstate"
NODES_STATE="${BASE_TF_DIR}/nodes.tfstate"
INFRA_STATE="${BASE_TF_DIR}/infra.tfstate"

CLUSTER_VARS="${BASE_TF_DIR}/cluster.tfvars"
NODES_VARS="${BASE_TF_DIR}/nodes.tfvars"
INFRA_VARS="${BASE_TF_DIR}/infra.tfvars"
