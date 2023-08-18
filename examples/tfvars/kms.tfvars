deploy_id        = "plantest004"
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
kms = {
  enabled = true
  # Replace with desired kms key_id
  key_id = "6222fa8b-419e-4d3e-b9bc-2427e38326d5"
}
