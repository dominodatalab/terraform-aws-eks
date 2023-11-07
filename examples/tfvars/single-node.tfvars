## DO NOT use this configuration for live environments.
deploy_id        = "plantest0011"
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

  bastion = {
    enabled = false
  }
}

single_node = {
  instance_type = "m5.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "dev-v2_sandbox_"
    owner       = "977170443939"

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

domino_cur = {
  provision_resources = true
  region = "us-east-1"
}