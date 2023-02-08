# Validating zone offerings.

# Check the zones where the instance types are being offered
data "aws_ec2_instance_type_offerings" "nodes" {
  for_each = { for name, ng in merge(var.default_node_groups, var.additional_node_groups) : name => ng.instance_types }

  filter {
    name   = "instance-type"
    values = each.value
  }

  location_type = "availability-zone"

  lifecycle {
    # Validating the number of zones is greater than 2. EKS needs at least 2.
    postcondition {
      condition     = length(toset(self.locations)) >= 2
      error_message = "Availability of the instance types does not satisfy the number of zones"
    }
  }
}

# Get "available" azs for the region
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

data "aws_subnet" "public" {
  count = var.vpc_id != null ? length(var.public_subnets) : 0
  id    = var.public_subnets[count.index]
}

data "aws_subnet" "private" {
  count = var.vpc_id != null ? length(var.private_subnets) : 0
  id    = var.private_subnets[count.index]
}

data "aws_subnet" "pod" {
  count = var.vpc_id != null ? length(var.pod_subnets) : 0
  id    = var.pod_subnets[count.index]
}

locals {
  # Get zones where ALL instance types are offered(intersection).
  zone_intersection_instance_offerings = setintersection([for k, v in data.aws_ec2_instance_type_offerings.nodes : toset(v.locations)]...)
  # Get the zones that are available and offered in the region for the instance types.
  az_names    = var.vpc_id != null ? distinct(data.aws_subnet.private[*].availability_zone) : length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  offered_azs = setintersection(local.zone_intersection_instance_offerings, toset(local.az_names))
  num_of_azs  = var.vpc_id != null ? length(local.az_names) : var.number_of_azs

  # error -> "Availability of the instance types does not satisfy the desired number of zones, or the desired number of zones is higher than the available/offered zones"
  azs_to_use = slice(tolist(local.offered_azs), 0, local.num_of_azs)

  kms_key_arn = var.use_kms ? try(data.aws_kms_key.key[0].arn, resource.aws_kms_key.domino[0].arn) : null
}

locals {
  bastion_user     = "ec2-user"
  ssh_pvt_key_path = abspath(pathexpand(var.ssh_pvt_key_path))
  kubeconfig_path  = var.kubeconfig_path != "" ? abspath(pathexpand(var.kubeconfig_path)) : "${path.cwd}/kubeconfig"
}

## Importing SSH pvt key to access bastion and EKS nodes

data "tls_public_key" "domino" {
  private_key_openssh = file(var.ssh_pvt_key_path)
}

resource "aws_key_pair" "domino" {
  key_name   = var.deploy_id
  public_key = trimspace(data.tls_public_key.domino.public_key_openssh)
}

module "storage" {
  source                        = "./submodules/storage"
  deploy_id                     = var.deploy_id
  efs_access_point_path         = var.efs_access_point_path
  s3_force_destroy_on_deletion  = var.s3_force_destroy_on_deletion
  s3_kms_key                    = local.kms_key_arn
  ecr_force_destroy_on_deletion = var.ecr_force_destroy_on_deletion
  ecr_kms_key                   = local.kms_key_arn
  efs_kms_key                   = local.kms_key_arn
  vpc_id                        = local.vpc_id
  subnet_ids                    = [for s in local.private_subnets : s.subnet_id]
}

locals {
  ## Calculating public and private subnets based on the base base cidr and desired network bits
  base_cidr_network_bits = tonumber(regex("[^/]*$", var.cidr))
  ## We have one Cidr to carve the nw bits for both pvt and public subnets
  ## `...local.availability_zones_number * 2)` --> we have 2 types private and public subnets
  new_bits_list      = concat([for n in range(0, local.num_of_azs) : var.public_cidr_network_bits - local.base_cidr_network_bits], [for n in range(0, local.num_of_azs) : var.private_cidr_network_bits - local.base_cidr_network_bits])
  subnet_cidr_blocks = cidrsubnets(var.cidr, local.new_bits_list...)

  ## Match the public subnet var to the list of cidr blocks
  public_cidr_blocks = slice(local.subnet_cidr_blocks, 0, local.num_of_azs)
  ## Match the private subnet var to the list of cidr blocks
  private_cidr_blocks = slice(local.subnet_cidr_blocks, local.num_of_azs, length(local.subnet_cidr_blocks))
  ## Determine cidr blocks for pod network
  base_pod_cidr_network_bits = tonumber(regex("[^/]*$", var.pod_cidr))
  pod_cidr_blocks = !var.use_pod_cidr ? [] : cidrsubnets(
    var.pod_cidr,
    [for n in range(0, local.num_of_azs) : var.pod_cidr_network_bits - local.base_pod_cidr_network_bits]...
  )
}

module "network" {
  count = var.vpc_id == null ? 1 : 0

  source              = "./submodules/network"
  deploy_id           = var.deploy_id
  region              = var.region
  cidr                = var.cidr
  pod_cidr            = var.pod_cidr
  use_pod_cidr        = var.use_pod_cidr
  availability_zones  = local.azs_to_use
  public_cidrs        = local.public_cidr_blocks
  private_cidrs       = local.private_cidr_blocks
  pod_cidrs           = local.pod_cidr_blocks
  flow_log_bucket_arn = { arn = module.storage.s3_buckets["monitoring"].arn }
}

locals {
  vpc_id          = var.vpc_id != null ? var.vpc_id : module.network[0].vpc_id
  public_subnets  = var.vpc_id != null ? [for s in data.aws_subnet.public : { subnet_id = s.id, az = s.availability_zone }] : module.network[0].public_subnets
  private_subnets = var.vpc_id != null ? [for s in data.aws_subnet.private : { subnet_id = s.id, az = s.availability_zone }] : module.network[0].private_subnets
  pod_subnets     = var.vpc_id != null ? [for s in data.aws_subnet.pod : { subnet_id = s.id, az = s.availability_zone }] : module.network[0].pod_subnets
}

module "bastion" {
  count = var.bastion != null ? 1 : 0

  source           = "./submodules/bastion"
  deploy_id        = var.deploy_id
  region           = var.region
  vpc_id           = local.vpc_id
  ssh_pvt_key_path = aws_key_pair.domino.key_name
  public_subnet_id = local.public_subnets[0].subnet_id
  ami_id           = var.bastion.ami
  instance_type    = var.bastion.instance_type
  kms_key          = local.kms_key_arn
  security_group_rules = {
    bastion_inbound_ssh = {
      protocol                 = "tcp"
      from_port                = "22"
      to_port                  = "22"
      type                     = "ingress"
      description              = "Inbound ssh"
      cidr_blocks              = var.bastion.authorized_ssh_ip_ranges
      source_security_group_id = null
    }
  }
}

locals {
  node_groups = {
    for name, ng in
    merge(var.additional_node_groups, var.default_node_groups) :
    name => merge(ng, { gpu = anytrue([for itype in ng.instance_types : length(data.aws_ec2_instance_type.all[itype].gpus) > 0]) })
  }
}

data "aws_ec2_instance_type" "all" {
  for_each      = toset(flatten([for ng in merge(var.additional_node_groups, var.default_node_groups) : ng.instance_types]))
  instance_type = each.value
}

module "eks" {
  source                       = "./submodules/eks"
  deploy_id                    = var.deploy_id
  region                       = var.region
  k8s_version                  = var.k8s_version
  vpc_id                       = local.vpc_id
  private_subnets              = local.private_subnets
  pod_subnets                  = local.pod_subnets
  ssh_key_pair_name            = aws_key_pair.domino.key_name
  bastion_security_group_id    = try(module.bastion[0].security_group_id, "")
  create_bastion_sg            = var.bastion != null
  kubeconfig_path              = local.kubeconfig_path
  node_groups                  = local.node_groups
  node_iam_policies            = module.storage.iam_policies
  efs_security_group           = module.storage.efs_security_group
  update_kubeconfig_extra_args = var.update_kubeconfig_extra_args
  eks_master_role_names        = var.eks_master_role_names
  ssh_pvt_key_path             = local.ssh_pvt_key_path
  bastion_user                 = local.bastion_user
  bastion_public_ip            = try(module.bastion[0].public_ip, "")
  secrets_kms_key              = local.kms_key_arn
  node_groups_kms_key          = local.kms_key_arn

  depends_on = [
    module.network
  ]
}
