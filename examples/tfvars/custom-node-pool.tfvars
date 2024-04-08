deploy_id        = "plantest002"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

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
  custom-0 = {
    instance_types = [
      "m6i.2xlarge"
    ],
    min_per_az     = 0,
    max_per_az     = 10,
    desired_per_az = 0,
    availability_zone_ids = [
      "usw2-az1",
      "usw2-az2"
    ],
    labels = {
      "dominodatalab.com/node-pool" = "custom-group-0"
    },
    volume = {
      size = 100,
      type = "gp3"
    }
  }
  custom-gpu-1 = {
    gpu = true
    ## Just for testing the `gpu` bool behavior
    instance_types = [
      "m6i.2xlarge"
    ],
    min_per_az     = 0,
    max_per_az     = 10,
    desired_per_az = 0,
    availability_zone_ids = [
      "usw2-az1",
      "usw2-az2"
    ],
    labels = {
      "dominodatalab.com/node-pool" = "custom-gpu-1 "
    },
    volume = {
      size = 100,
      type = "gp3"
    }
  }
  custom-gpu-2 = {
    instance_types = [
      "g5.xlarge"
    ],
    min_per_az     = 0,
    max_per_az     = 10,
    desired_per_az = 0,
    availability_zone_ids = [
      "usw2-az1",
      "usw2-az2"
    ],
    labels = {
      "dominodatalab.com/node-pool" = "custom-gpu-2 "
    },
    volume = {
      size = 100,
      type = "gp3"
    }
  }
  custom-gpu-3 = {
    instance_types = [
      "g5.xlarge"
    ],
    min_per_az     = 0,
    max_per_az     = 10,
    desired_per_az = 0,
    availability_zone_ids = [
      "usw2-az1",
      "usw2-az2"
    ],
    labels = {
      "dominodatalab.com/node-pool" = "custom-gpu-3 "
    },
    volume = {
      size = 100,
      type = "gp3"
    }
    taints = [{
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }
}
