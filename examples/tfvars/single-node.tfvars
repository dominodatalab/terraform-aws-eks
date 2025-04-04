## DO NOT use this configuration for live environments.
deploy_id        = "plantest0011"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
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

  bastion = {
    enabled = false
  }
}

single_node = {
  instance_type = "m6i.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "amazon-eks-node-al2023-x86_64-standard-"
    owner       = "602401143452"
  }
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  },
}

storage = {
  s3 = {
    force_destroy_on_deletion = true
  },
  costs_enabled = false
}

## The following will ALSO need to be set in the cluster.tfvars
eks = {
  k8s_version = "1.28"
}
