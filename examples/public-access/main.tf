module "domino_eks" {
  source           = "./../.."
  region           = "us-west-2"
  ssh_pvt_key_path = "./../examples.pem"
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
  eks = {
    public_access = {
      enabled = true
      cidrs   = ["10.0.0.0/8"] # Replace this with the desired CIDR range

    }
  }
}
