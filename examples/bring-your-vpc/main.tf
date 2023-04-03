
module "domino_eks" {
  source           = "./../.."
  region           = var.region
  ssh_pvt_key_path = "./../examples.pem"
  deploy_id        = "dominoeks001"
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

  bastion = {
    enabled = true
  }
  network = {
    ## The following are not real values
    vpc = {
      id = "vpc-notrealb8ca349af"
      subnets = {
        private = ["subnet-notrealvalb2319f", "subnet-notrealval9be2580"]
        public  = ["subnet-notrealval126cd0", "subnet-notrealval178f224"]
        pod     = ["subnet-notrealval126cgf4", "subnet-notrealval178f64"]
      }
    }
    use_pod_cidr = false
  }
}
