deploy_id        = "plantest007"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

eks = {
  k8s_version = "1.26"
}

default_node_groups = {
  compute = {
    ami                   = "ami-03c98ebe506f3c7be" #Update with desired AMI
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    ami                   = "ami-03c98ebe506f3c7be" #Update with desired AMI
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    ami                   = "ami-07d2175f696d9b671" #Update with desired GPU AMI
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}

