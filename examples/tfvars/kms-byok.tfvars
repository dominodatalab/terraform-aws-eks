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
  # If bringing your own replace with desired kms key_id
  key_id = "your-own-kms-key-id"
}

domino_cur = {
  provision_resources = true
  region = "us-east-1"
}