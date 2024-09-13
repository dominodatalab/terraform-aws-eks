deploy_id        = "ed-test-001"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    "availability_zone_ids" = ["usw2-az1", "usw2-az2"]
  }
}

bastion = {
  enabled = true
}

irsa_external_deployments_operator = {
  enabled                   = "true",
  namespace                 = "domino-compute",
  service_account_name      = "test-operator-account",
  region                    = "us-west-2"
  role_suffix               = "external-deployments-operator",
  repository_suffix         = "external-deployments",
  bucket_suffix             = "external-deployments",
  grant_assume_any_role     = "true",
  grant_in_account_policies = "true"
}
