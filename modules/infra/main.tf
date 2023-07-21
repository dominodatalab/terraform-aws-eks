
module "domino_eks" {
  source           = "./../../submodules/infra"
  region           = var.region
  ssh_pvt_key_path = "/home/mrgus/.ssh/domino-test-rotated.pem"
  deploy_id        = var.deploy_id
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
    enabled          = true
    install_binaries = true
  }
}
