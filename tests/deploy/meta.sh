#!/usr/bin/env bash

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

CI_DEPLOY="true"
DEPLOY_DIR="${SH_DIR}/deploy-test"
PVT_KEY="${DEPLOY_DIR}/domino.pem"

INFRA_VARS_TPL="${SH_DIR}/infra-ci.tfvars.tftpl"
CLUSTER_VARS_TPL="${SH_DIR}/cluster-ci.tfvars.tftpl"

declare -A COMP_MODS
COMP_MODS["infra"]="infra"
COMP_MODS["cluster"]="eks irsa_external_dns irsa_policies"
COMP_MODS["nodes"]="nodes"

declare -A MOD_ADD
MOD_ADD["irsa_external_dns"]="eks/submodules/irsa"
MOD_ADD["irsa_policies"]="eks/submodules/irsa"

export SH_DIR \
  CI_DEPLOY \
  DEPLOY_DIR \
  PVT_KEY \
  INFRA_VARS_TPL \
  CLUSTER_VARS_TPL \
  COMP_MODS \
  MOD_ADD
