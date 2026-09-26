#!/usr/bin/env bash

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

if [ -n "${DEPLOY_DIR:-}" ]; then
  BASE_TF_DIR="${DEPLOY_DIR}/terraform"
else
  BASE_TF_DIR="${SH_DIR}/terraform"
fi

declare -a MOD_DIRS=(
  "${BASE_TF_DIR}/infra"
  "${BASE_TF_DIR}/cluster"
  "${BASE_TF_DIR}/nodes"
  "${BASE_TF_DIR}/load_balancers"
)

declare -A COMP_MODS
COMP_MODS["infra"]="infra"
COMP_MODS["cluster"]="eks irsa_external_dns irsa_policies external_deployments_operator flyte"
COMP_MODS["nodes"]="nodes"
COMP_MODS["load_balancers"]="load_balancers privatelink"

declare -A MOD_ADD
MOD_ADD["irsa_external_dns"]="irsa"
MOD_ADD["irsa_policies"]="irsa"
MOD_ADD["external_deployments_operator"]="external-deployments"

INFRA_DIR="${MOD_DIRS[0]}"
CLUSTER_DIR="${MOD_DIRS[1]}"
NODES_DIR="${MOD_DIRS[2]}"
LOAD_BALANCERS_DIR="${MOD_DIRS[3]}"

CLUSTER_STATE="${BASE_TF_DIR}/cluster.tfstate"
NODES_STATE="${BASE_TF_DIR}/nodes.tfstate"
INFRA_STATE="${BASE_TF_DIR}/infra.tfstate"
LOAD_BALANCERS_STATE="${BASE_TF_DIR}/load_balancers.tfstate"

CLUSTER_VARS="${BASE_TF_DIR}/cluster.tfvars"
NODES_VARS="${BASE_TF_DIR}/nodes.tfvars"
INFRA_VARS="${BASE_TF_DIR}/infra.tfvars"
LOAD_BALANCERS_VARS="${BASE_TF_DIR}/load_balancers.tfvars"

export BASE_TF_DIR \
  MOD_DIRS \
  COMP_MODS \
  MOD_ADD \
  INFRA_DIR \
  CLUSTER_DIR \
  NODES_DIR \
  LOAD_BALANCERS_DIR \
  CLUSTER_STATE \
  NODES_STATE \
  INFRA_STATE \
  LOAD_BALANCERS_STATE \
  CLUSTER_VARS \
  NODES_VARS \
  INFRA_VARS \
  LOAD_BALANCERS_VARS
