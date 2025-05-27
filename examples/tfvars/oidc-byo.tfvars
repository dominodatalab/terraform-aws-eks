deploy_id        = "plantest019"
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
    "availability_zone_ids" = ["usw2-az1", "usw2-az2"]
  }
}

bastion = {
  enabled = true
}

kms = {
  enabled = true
}

eks = {
  oidc_provider = {
    create = true
    oidc = {
      arn             = "_CHANGE_ME_"
      client_id_list  = ["sts.amazonaws.com"]
      id              = "_CHANGE_ME_"
      thumbprint_list = ["_CHANGE_ME_"]
      url             = "_CHANGE_ME_"
    }
  }
}
