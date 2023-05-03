data "terraform_remote_state" "kms_key" {
  backend = "local"

  config = {
    path = "${path.module}/../create-kms-key/terraform.tfstate"
  }
}


module "domino_eks" {
  source           = "./../.."
  region           = var.region
  ssh_pvt_key_path = "./../examples.pem"
  deploy_id        = "dominoeks003"
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
  kms = {
    enabled = true
    key_id  = data.terraform_remote_state.kms_key.outputs.kms_key_id
  }
}
