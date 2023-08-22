deploy_id        = "dominoeks001"
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
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}

bastion = {
  enabled = true
}
kms = {
  enabled = true
}

tags = {
  deploy_id   = "dominoeks001"
  deploy_type = "terraform-aws-eks"
}
