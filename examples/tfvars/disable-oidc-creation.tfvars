deploy_id        = "plantest0018"
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

#Set in the cluster.tfvars file.
#Disables the creation of the OIDC provider.
#Note that the OIDC provider is required for IRSA implementations.
#Check the oidc-provider example for how to create the OIDC provider, and what the expected fields below are.
eks = {
  oidc_provider = {
    create = false
    oidc   = null
  }
}


tags = {}
