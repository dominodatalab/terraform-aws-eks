data "aws_availability_zone" "zones" {
  for_each = toset(var.availability_zone_ids)
  zone_id  = each.value
}

locals {
  zone_id_by_name = { for az_id in var.availability_zone_ids : data.aws_availability_zone.zones[az_id].name => az_id }
  az_names        = sort(keys(local.zone_id_by_name))

  ## Get the public subnets by matching the mask and populating its params
  public_cidrs = { for i, cidr in var.public_cidrs : cidr =>
    {
      "az_id" = local.zone_id_by_name[local.az_names[i]]
      "az"    = local.az_names[i]
      "name"  = "${var.deploy_id}-public-${local.az_names[i]}"
    }
  }

  ## Get the private subnets by matching the mask and populating its params
  private_cidrs = { for i, cidr in var.private_cidrs : cidr =>
    {
      "az_id" = local.zone_id_by_name[local.az_names[i]]
      "az"    = local.az_names[i]
      "name"  = "${var.deploy_id}-private-${local.az_names[i]}"
    }
  }

  ## Get the pod subnets by matching the mask and populating its params
  pod_cidrs = { for i, cidr in var.pod_cidrs : cidr =>
    {
      "az_id" = local.zone_id_by_name[local.az_names[i]]
      "az"    = local.az_names[i]
      "name"  = "${var.deploy_id}-pod-${local.az_names[i]}"
    }
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_cidrs

  availability_zone_id = each.value.az_id
  vpc_id               = local.vpc_id
  cidr_block           = each.key
  tags = merge(
    { "Name" : each.value.name },
    var.add_eks_elb_tags ? {
      "kubernetes.io/role/elb"                 = "1"
      "kubernetes.io/cluster/${var.deploy_id}" = "shared"
  } : {})

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_cidrs

  availability_zone_id = each.value.az_id
  vpc_id               = local.vpc_id
  cidr_block           = each.key
  tags = merge(
    { "Name" : each.value.name },
    var.add_eks_elb_tags ? {
      "kubernetes.io/role/internal-elb"        = "1"
      "kubernetes.io/cluster/${var.deploy_id}" = "shared"
  } : {})

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "pod" {
  for_each = local.pod_cidrs

  availability_zone_id = each.value.az_id
  vpc_id               = local.vpc_id
  cidr_block           = each.key
  tags = merge(
    { "Name" : each.value.name },
    var.add_eks_elb_tags ? {
      "kubernetes.io/role/internal-elb"        = "1"
      "kubernetes.io/cluster/${var.deploy_id}" = "shared"
  } : {})

  lifecycle {
    ignore_changes = [tags]
  }

  ## See https://github.com/hashicorp/terraform-provider-aws/issues/9592
  depends_on = [aws_vpc_ipv4_cidr_block_association.pod_cidr[0]]
}
