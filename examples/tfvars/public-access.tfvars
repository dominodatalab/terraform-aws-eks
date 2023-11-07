deploy_id        = "plantest008"
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

  eks = {
    public_access = {
      enabled = true
      cidrs   = ["108.214.49.0/24"] # Replace this with the desired CIDR range

    }
  }
}

domino_cur = {
  provision_resources = false
  region = "us-east-1"
}