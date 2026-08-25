deploy_id        = "plantest021"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## arm64 (Graviton) node groups. Architecture is auto-detected from instance_types
## (see modules/nodes/main.tf local.node_group_status.is_arm64), so `arch` is
## only needed when you want to force it explicitly (e.g. a custom `ami` where the
## instance type alone doesn't make the arch obvious).
## The following (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}

additional_node_groups = {
  compute-arm64 = {
    instance_types = [
      "m6g.xlarge"
    ],
    min_per_az     = 0,
    max_per_az     = 10,
    desired_per_az = 0,
    availability_zone_ids = [
      "usw2-az1",
      "usw2-az2"
    ],
    labels = {
      "dominodatalab.com/node-pool" = "compute-arm64"
    },
    volume = {
      size = 100,
      type = "gp3"
    }
  }
  gpu-arm64 = {
    ## `gpu` is still auto-detected from the instance type (g5g has a T4G GPU), just
    ## like on the x86_64 gpu node group - no explicit `gpu = true` required here either.
    instance_types = [
      "g5g.xlarge"
    ],
    min_per_az     = 0,
    max_per_az     = 10,
    desired_per_az = 0,
    availability_zone_ids = [
      "usw2-az1",
      "usw2-az2"
    ],
    labels = {
      "dominodatalab.com/node-pool" = "gpu-arm64"
    },
    volume = {
      size = 100,
      type = "gp3"
    }
  }
}
