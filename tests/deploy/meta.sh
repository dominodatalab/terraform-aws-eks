#!/usr/bin/env bash
set -x #todo rm
echo "ci vars"
SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

CI_DEPLOY="true"
DEPLOY_DIR="${SH_DIR}/deploy-test"
PVT_KEY="${DEPLOY_DIR}/domino.pem"

LEGACY_DIR="${SH_DIR}/legacy-test"
LEGACY_TF="${LEGACY_DIR}/main.tf.json"
LEGACY_STATE="${LEGACY_DIR}/terraform.tfstate"
LEGACY_PVT_KEY="${LEGACY_DIR}/domino.pem"

INFRA_VARS_TPL="${SH_DIR}/infra-ci.tfvars.tftpl"

export SH_DIR CI_DEPLOY DEPLOY_DIR LEGACY_DIR LEGACY_TF PVT_KEY LEGACY_STATE LEGACY_PVT_KEY INFRA_VARS_TPL
