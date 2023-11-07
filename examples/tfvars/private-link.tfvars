deploy_id        = "plantest009"
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

  ## bastion is enabled by default
  bastion = {
    enabled = true
  }
}

enable_private_link      = true
route53_hosted_zone_name = "domino"

domino_cur = {
  provision_resources = false
  region = "us-east-1"
}
