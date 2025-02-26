deploy_id        = "plantest0015"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}

bastion = {
  enabled = false
}


## The following will ALSO need to be set in the cluster.tfvars
eks = {
  identity_providers = [{
    client_id                     = "fake-client-id"
    groups_claim                  = "groups"
    groups_prefix                 = "group:"
    identity_provider_config_name = "idp"
    issuer_url                    = "https://example.com"
    username_claim                = "email"
    username_prefix               = "user:"
    required_claims = {
      key = "value"
    }
  }]

  public_access = {
    enabled = true
    cidrs   = ["108.214.49.0/24"] # Replace this with the desired CIDR range
  }
}
