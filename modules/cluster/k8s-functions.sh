#! /usr/bin/env bash

RED="\e[31m"
GREEN="\e[32m"
EC="\e[0m"

KUBECONFIG="/home/mrgus/domino/terraform-aws-eks/modules/cluster/kubeconfig"
KUBECONFIG_PROXY="$KUBECONFIG-proxy"
TUNNEL_SOCKET_FILE=${TUNNEL_SOCKET_FILE:-/tmp/k8s-tunnel-socket-63834}

open_ssh_tunnel_to_k8s_api() {
  if [[ -n "44.228.70.128" && -n "ec2-user" ]]; then
    printf "$GREEN Opening k8s tunnel ... $EC \n"
    ssh-keygen -R "44.228.70.128" || true
    chmod 400 "/home/mrgus/.ssh/domino-test-rotated.pem"
    ssh -q -N -f -M -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -i "/home/mrgus/.ssh/domino-test-rotated.pem" -D 63834 -S "$TUNNEL_SOCKET_FILE" ec2-user@44.228.70.128
  else
    printf "$GREEN No bastion, no tunnel needed... $EC \n"
  fi
}

check_kubeconfig() {
  printf "$GREEN Checking if $KUBECONFIG exists... $EC \n"
  if test -f "$KUBECONFIG"; then
    if [[ -n "44.228.70.128" ]]; then
      echo "$KUBECONFIG exists, creating $KUBECONFIG_PROXY for proxy use."
      cp $KUBECONFIG $KUBECONFIG_PROXY
      kubectl --kubeconfig $KUBECONFIG_PROXY config set "clusters.arn:aws:eks:us-west-2:890728157128:cluster/joaquintest040.proxy-url" "socks5://127.0.0.1:63834"
      export kubeconfig=$KUBECONFIG_PROXY
    else
      export kubeconfig=$KUBECONFIG
    fi
  else
    echo "$KUBECONFIG does not exist." && exit 1
  fi
  echo
}

set_k8s_auth() {
  local AWS_AUTH_YAML="aws-auth.yaml"
  if test -f "$AWS_AUTH_YAML"; then
    printf "$GREEN Updating $AWS_AUTH_YAML... $EC \n"
    kubectl_apply "$AWS_AUTH_YAML"
  else
    printf "$RED $AWS_AUTH_YAML does not exist. $EC \n" && exit 1
  fi
  echo
}

set_eniconfig() {
  local ENICONFIG_YAML="eniconfig.yaml"
  if [ -z "$ENICONFIG_YAML" ]; then
    return
  fi
  if test -f "$ENICONFIG_YAML"; then
    printf "$GREEN Updating $ENICONFIG_YAML... $EC \n"
    kubectl_apply "$ENICONFIG_YAML"
  else
    printf "$RED $ENICONFIG_YAML does not exist. $EC \n" && exit 1
  fi
  echo
  kubectl_cmd -n kube-system set env daemonset aws-node AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
}

remove_calico_cr() {
  local WAIT_TIME=300
  local SLEEP_TIME=5
  local COUNTER=0

  printf "$GREEN Removing Calico CRDs...$EC \n"
  kubectl_cmd delete installation default --ignore-not-found=true

  while kubectl --kubeconfig "$kubeconfig" get namespaces -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -q '^calico-system$'; do
    if [ $COUNTER -ge $WAIT_TIME ]; then
      printf "$RED Timed out waiting for calico-system namespace to be fully deleted.$EC \n"
      exit 1
    fi

    printf "$GREEN Waiting for calico-system namespace to be fully deleted...$EC \n"
    sleep $SLEEP_TIME
    COUNTER=$((COUNTER + SLEEP_TIME))
  done
  printf "$GREEN calico-system namespace was deleted successfully...$EC \n"
}

remove_tigera_operator() {
  printf "$GREEN Removing existing Tigera operator...$EC \n"
  kubectl_cmd delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml \
    --ignore-not-found=true \
    --force \
    --grace-period=0
  echo
  printf "$GREEN Tigera operator was removed successfully...$EC \n"
}

check_remove_calico() {
  local OPERATOR_DEPLOYMENT_NAME="tigera-operator"
  local OPERATOR_NAMESPACE="tigera-operator"
  local calico_deploy=""
  local managed_by=""

  calico_deploy="$(kubectl --kubeconfig "$kubeconfig" get deployment $OPERATOR_DEPLOYMENT_NAME -n $OPERATOR_NAMESPACE --no-headers=true --ignore-not-found=true)"

  if [ -n "$calico_deploy" ]; then
    managed_by=$(kubectl --kubeconfig "$kubeconfig" get deployment $OPERATOR_DEPLOYMENT_NAME -n $OPERATOR_NAMESPACE -o jsonpath="{.metadata.labels['app\.kubernetes\.io/managed-by']}")
    if [ -z "$managed_by" ] || [ "$managed_by" != "Helm" ]; then
      remove_calico_cr
      remove_tigera_operator
    fi
  fi
}

install_calico() {
  check_remove_calico

  printf "$GREEN Installing Calico Operator $EC \n"
  helm_cmd upgrade "calico-tigera-operator" \
    tigera-operator \
    --repo "https://projectcalico.docs.tigera.io/charts" \
    --kubeconfig "$kubeconfig" \
    --namespace "tigera-operator" \
    --version "v3.25.0" \
    --set installation.kubernetesProvider=EKS \
    --set installation.cni.type=AmazonVPC \
    --set installation.registry="quay.io/" \
    --timeout 10m \
    --create-namespace \
    --install

  echo
}

validate_url() {
  local url="$1"
  local log_file="validate-url.log"
  if curl --head --fail --max-time 10 --output "$log_file" --stderr "$log_file" "$url"; then
    rm "$log_file" && return 0
  else
    cat "$log_file" && return 1
  fi
}

kubectl_apply() {
  local k8s_manifest=$1
  if test -f "$k8s_manifest" || validate_url "$k8s_manifest"; then
    printf "$GREEN Applying $k8s_manifest...$EC \n"
    kubectl_cmd apply -f $k8s_manifest
  else
    printf "$RED $k8s_manifest does not exist. $EC \n"
    exit 1
  fi
}

helm_cmd() {
  printf "$GREEN Running helm $@...$EC \n"
  helm --kubeconfig "$kubeconfig" $@
  if [ $? -ne 0 ]; then
    printf "$RED Error running helm $@ $EC \n"
    exit 1
  fi
}

kubectl_cmd() {
  printf "$GREEN  kubectl $@... $EC \n"
  kubectl --kubeconfig "$kubeconfig" $@
  if [ $? -ne 0 ]; then
    printf "$RED Error running kubectl $@ $EC \n"
    exit 1
  fi
}

close_ssh_tunnel_to_k8s_api() {
  if [[ -n "44.228.70.128" ]]; then
    printf "$GREEN Shutting down k8s tunnel ... $EC"
    ssh -S $TUNNEL_SOCKET_FILE -O exit ec2-user@44.228.70.128
  fi
}
