deploy_id        = "plantest0017"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

default_node_groups = null
additional_node_groups = {
  dataplane = {
    instance_types        = ["m6i.2xlarge"]
    min_per_az            = 0
    max_per_az            = 10
    desired_per_az        = 1
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
    labels = {
      "dominodatalab.com/node-pool" = "dataplane"
    }
    volume = {
      size = 100
      type = "gp3"
    }
  }
}

bastion = {
  enabled = false
}

storage = {
  s3              = { "create" : false }
  ecr             = { "create" : false }
  filesystem_type = "none"
}
