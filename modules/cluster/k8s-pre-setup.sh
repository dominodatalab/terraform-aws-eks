#! /usr/bin/env bash

set -ex

source k8s-functions.sh

trap close_ssh_tunnel_to_k8s_api EXIT
open_ssh_tunnel_to_k8s_api
check_kubeconfig

for arg in "$@"; do
  "$arg"
done
