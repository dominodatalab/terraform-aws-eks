deploy_id        = "plantest021"
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
