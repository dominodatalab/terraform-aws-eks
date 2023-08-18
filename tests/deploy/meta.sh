#!/usr/bin/env bash

: "${SH_DIR:=$(cd "$(dirname "$0")" && pwd)}"

DEPLOY_DIR="${SH_DIR}/deploy-test"
LEGACY_DIR="${SH_DIR}/legacy-test"
LEGACY_TF="${LEGACY_DIR}/main.tf.json"
PVT_KEY="${DEPLOY_DIR}/domino.pem"
LEGACY_PVT_KEY="${LEGACY_DIR}/domino.pem"

export SH_DIR DEPLOY_DIR LEGACY_DIR LEGACY_TF PVT_KEY LEGACY_PVT_KEY
