deploy_id        = "plantest003"
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

use_fips_endpoint = true

## The following will ALSO need to be set in the cluster.tfvars
eks = {
  public_access = {
    enabled = true
    cidrs   = ["0.0.0.0/0"]

  }
}
