deploy_id        = "plantest021"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## arm64 (Graviton) node groups. `arch` is the only source of truth for whether a
## node group is arm64 (see modules/nodes/main.tf local.node_group_status.is_arm64),
## so it must be set explicitly here - it is never inferred from instance_types.
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
  ## Neither this node group's name nor its label mentions arm/arm64, proving that
  ## AMI selection (see modules/nodes/main.tf local.node_group_ami_class_types)
  ## follows only the explicit `arch` field below, never the node group's name.
  workers = {
    arch = "arm64"
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
      "dominodatalab.com/node-pool" = "workers"
    },
    volume = {
      size = 100,
      type = "gp3"
    }
  }
  gpu-arm64 = {
    ## `gpu` is still auto-detected from the instance type (g5g has a T4G GPU), just
    ## like on the x86_64 gpu node group - no explicit `gpu = true` required here either.
    arch = "arm64"
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
