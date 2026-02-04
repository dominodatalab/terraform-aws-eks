deploy_id        = "plantest011"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## Example demonstrating the platform_jobs node group
## This is an optional node group for running platform background jobs on cheaper instances
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
  platform_jobs = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
    ## Override defaults if needed:
    # instance_types = ["m7i-flex.xlarge"]
    # min_per_az     = 0
    # max_per_az     = 5
    # desired_per_az = 1
  }
}

bastion = {
  enabled = true
}
