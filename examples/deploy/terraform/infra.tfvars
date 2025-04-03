deploy_id        = "mh002"
region           = "us-west-2"
ssh_pvt_key_path = "/Users/miguel.harmant/src/dominodatalab/terraform-aws-eks/tests/domino.pem"

# default_node_groups = {
#   compute = {
#     availability_zone_ids = ["usw2-az1"]
#     instance_types = [
#       "m4.2xlarge",
#       "m5.2xlarge",
#       "m5a.2xlarge",
#       "m5ad.2xlarge",
#       "m5d.2xlarge",
#       "m5dn.2xlarge",
#       "m5n.2xlarge",
#       "m5zn.2xlarge",
#       "m6id.2xlarge"
#     ]
#   }
#   gpu = {
#     availability_zone_ids = ["usw2-az2"]
#   }
#   platform = {
#     "availability_zone_ids" = ["usw2-az2"]
#   }
# }

# additional_node_groups = {
#   other_az = {
#     availability_zone_ids = ["usw2-az3"]
#     desired_per_az        = 0
#     instance_types        = ["m5.2xlarge"]
#     labels = {
#       "dominodatalab.com/node-pool" = "other-az"
#     }
#     max_per_az = 10
#     min_per_az = 0
#     volume = {
#       size = 100
#       type = "gp3"
#     }
#   }
# }

additional_node_groups = null
default_node_groups    = null

bastion = {
  enabled          = true
  install_binaries = true
}

eks = {
  k8s_version       = "1.32"
  master_role_names = ["okta-poweruser", "okta-fulladmin"]
}

kms = {
  "enabled" = true
}

tags = {
  deploy_id  = "mh002"
  lcoal_test = "true"
}

karpenter_node_groups = {
  karpenter = {
    availability_zone_ids = ["usw2-az1", "usw2-az2", "usw2-az3"]
    single_nodegroup      = true
  }
}
