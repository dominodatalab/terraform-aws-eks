deploy_id        = "plantest007"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
default_node_groups = {
  compute = {
    ami                   = "ami-09222788e7e90420c" #Update with desired AMI
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    ami                   = "ami-09222788e7e90420c" #Update with desired AMI
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    ami                   = "ami-00a5daece3b11427f" #Update with desired GPU AMI
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}

## The following will ALSO need to be set in the cluster.tfvars
eks = {
  k8s_version = "1.31"
}
