data "aws_ami" "eks_node" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.25-*"]
  }

  filter {
    name   = "owner-id"
    values = ["602401143452"] # Amazon EKS AMI account ID
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# GPU
data "aws_ami" "eks_gpu_node" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-1.25-*"]
  }

  filter {
    name   = "owner-id"
    values = ["602401143452"] # Amazon EKS AMI account ID
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "domino_eks" {
  source           = "./../.."
  region           = var.region
  ssh_pvt_key_path = "./../examples.pem"
  deploy_id        = "dominoeks005"
  default_node_groups = {
    compute = {
      ami                   = data.aws_ami.eks_node.image_id
      availability_zone_ids = ["usw2-az1", "usw2-az2"]
    }
    platform = {
      ami                   = data.aws_ami.eks_node.image_id
      availability_zone_ids = ["usw2-az1", "usw2-az2"]
    }
    gpu = {
      ami                   = data.aws_ami.eks_gpu_node.id
      availability_zone_ids = ["usw2-az1", "usw2-az2"]
    }
  }

  bastion = {
    enabled          = true
    install_binaries = true
  }
}
