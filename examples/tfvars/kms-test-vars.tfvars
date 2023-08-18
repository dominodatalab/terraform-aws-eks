deploy_id        = "plantest003"
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
  key_id = "1a6a2fe3-517e-4e88-ada8-6f668eae1045"
}
