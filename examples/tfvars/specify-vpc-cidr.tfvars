deploy_id        = "plantest018"
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
network = {
  network_bits = { ## Bits need to be less than cidrs.vpc bits
    public  = 27
    private = 21
    pod     = 20
  }
  cidrs = {
    vpc = "10.0.0.0/19"
  }
  use_pod_cidr = false
}
