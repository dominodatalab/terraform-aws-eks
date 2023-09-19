data "aws_availability_zone" "zones" {
  for_each = toset(local.az_ids)
  zone_id  = each.value
}

locals {
  zone_id_by_name = { for az_id in local.az_ids : data.aws_availability_zone.zones[az_id].name => az_id }
  az_names        = sort(keys(local.zone_id_by_name))

  ## Get the public subnets by matching the mask and populating its params
  public_cidrs = local.create_vpc ? { for i, cidr in local.public_cidr_blocks : cidr =>
    {
      "az_id" = local.zone_id_by_name[local.az_names[i]]
      "az"    = local.az_names[i]
      "name"  = "${var.deploy_id}-public-${local.az_names[i]}"
    }
  } : {}

  ## Get the private subnets by matching the mask and populating its params
  private_cidrs = local.create_vpc ? { for i, cidr in local.private_cidr_blocks : cidr =>
    {
      "az_id" = local.zone_id_by_name[local.az_names[i]]
      "az"    = local.az_names[i]
      "name"  = "${var.deploy_id}-private-${local.az_names[i]}"
    }
  } : {}

  ## Get the pod subnets by matching the mask and populating its params
  pod_cidrs = local.create_vpc ? { for i, cidr in local.pod_cidr_blocks : cidr =>
    {
      "az_id" = local.zone_id_by_name[local.az_names[i]]
      "az"    = local.az_names[i]
      "name"  = "${var.deploy_id}-pod-${local.az_names[i]}"
    }
  } : {}
}

resource "aws_subnet" "public" {
  for_each = local.public_cidrs

  availability_zone_id = each.value.az_id
  vpc_id               = aws_vpc.this[0].id
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
  vpc_id               = aws_vpc.this[0].id
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
  vpc_id               = aws_vpc.this[0].id
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
