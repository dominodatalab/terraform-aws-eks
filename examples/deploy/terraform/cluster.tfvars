eks = {
  cluster_addons     = null
  creation_role_name = null
  custom_role_maps   = null
  identity_providers = null
  k8s_version        = "1.32"
  kubeconfig = {
    extra_args = null
    path       = null
  }
  master_role_names = null
  public_access = {
    cidrs   = null
    enabled = null
  }
  service_ipv4_cidr  = null
  ssm_log_group_name = null
  vpc_cni            = null
}
external_deployments_operator = {
  bucket_suffix                   = "external-deployments"
  enable_assume_any_external_role = true
  enable_in_account_deployments   = true
  enabled                         = false
  namespace                       = "domino-compute"
  operator_role_suffix            = "external-deployments-operator"
  operator_service_account_name   = "pham-juno-operator"
  repository_suffix               = "external-deployments"
}
irsa_external_dns = {
  enabled          = false
  hosted_zone_name = null
  namespace        = null
  rm_role_policy = {
    detach_from_role = false
    policy_name      = ""
    remove           = false
  }
  serviceaccount_name = null
}
irsa_policies     = []
kms_info          = null
use_fips_endpoint = false

karpenter = {
  enabled = true
  version = "1.3.2"
}
