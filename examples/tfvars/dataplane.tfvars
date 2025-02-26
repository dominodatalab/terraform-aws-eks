deploy_id        = "plantest0017"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"


## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az2"]
  }
  platform = {
    availability_zone_ids = ["usw2-az2"]
  }
}

additional_node_groups = null
bastion = {
  enabled = false
}

storage = {
  s3              = { "create" : false }
  ecr             = { "create" : false }
  filesystem_type = "none"
}

## The following will ALSO need to be set in the cluster.tfvars
eks = {
  public_access = {
    enabled = true
    cidrs   = ["0.0.0.0/0"]

  }
}
