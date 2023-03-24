module "domino_eks" {
  source           = "./../.."
  region           = "us-west-2"
  ssh_pvt_key_path = "domino.pem"
  deploy_id        = "dominoeks"
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
  bastion = {}
}
