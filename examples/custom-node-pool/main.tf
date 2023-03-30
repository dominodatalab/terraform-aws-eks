module "domino_eks" {
  source           = "./../.."
  region           = var.region
  ssh_pvt_key_path = "./../examples.pem"
  deploy_id        = "dominoeks002"
  bastion          = {}
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
    custom-group-0 = {
      instance_types = [
        "m5.2xlarge"
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
  }

}
