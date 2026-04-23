deploy_id        = "plantest007"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
default_node_groups = {
  compute = {
    ami                   = "ami-002495de7d30f195d" #Update with desired AMI, this is amazon-eks-node-al2023-x86_64-standard-1.34-v20260116
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    ami                   = "ami-002495de7d30f195d" #Update with desired AMI, this is amazon-eks-node-al2023-x86_64-standard-1.34-v20260116
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    ami                   = "ami-096d0f8a5842c603c" #Update with desired GPU AMI, this is amazon-eks-node-al2023-x86_64-nvidia-1.34-v20260116
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}

## The following will ALSO need to be set in the cluster.tfvars
eks = {
  k8s_version = "1.34"
}
