locals {
  create_vpc = var.network.vpc.id == null
}

data "aws_subnet" "public" {
  count = !local.create_vpc ? length(var.network.vpc.subnets.public) : 0
  id    = var.network.vpc.subnets.public[count.index]
}

data "aws_subnet" "private" {
  count = !local.create_vpc ? length(var.network.vpc.subnets.private) : 0
  id    = var.network.vpc.subnets.private[count.index]
}

data "aws_subnet" "pod" {
  count = !local.create_vpc && var.network.use_pod_cidr ? length(var.network.vpc.subnets.pod) : 0
  id    = var.network.vpc.subnets.pod[count.index]
}

locals {
  # Get the zones that are available and offered in the region for the instance types.
  az_ids     = !local.create_vpc ? distinct(data.aws_subnet.private[*].availability_zone_id) : distinct(flatten([for name, ng in var.node_groups : ng.availability_zone_ids]))
  num_of_azs = length(local.az_ids)


  ## Calculating public and private subnets based on the base base cidr and desired network bits
  base_cidr_network_bits = tonumber(regex("[^/]*$", var.network.cidrs.vpc))
  ## We have one Cidr to carve the nw bits for both pvt and public subnets
  ## `...local.availability_zones_number * 2)` --> we have 2 types private and public subnets
  new_bits_list      = concat([for n in range(0, local.num_of_azs) : var.network.network_bits.public - local.base_cidr_network_bits], [for n in range(0, local.num_of_azs) : var.network.network_bits.private - local.base_cidr_network_bits])
  subnet_cidr_blocks = cidrsubnets(var.network.cidrs.vpc, local.new_bits_list...)

  ## Match the public subnet var to the list of cidr blocks
  public_cidr_blocks = try(data.aws_subnet.public[0].cidr_block, slice(local.subnet_cidr_blocks, 0, local.num_of_azs))
  ## Match the private subnet var to the list of cidr blocks
  private_cidr_blocks = try(data.aws_subnet.private[0].cidr_block, slice(local.subnet_cidr_blocks, local.num_of_azs, length(local.subnet_cidr_blocks)))
  ## Determine cidr blocks for pod network
  base_pod_cidr_network_bits = try(tonumber(regex("[^/]*$", var.network.cidrs.pod)), "")
  pod_cidr_blocks = try(data.aws_subnet.pod[0].cidr_block,
    !var.network.use_pod_cidr ? [] :
    cidrsubnets(var.network.cidrs.pod,
      [for n in range(0, local.num_of_azs) :
    var.network.network_bits.pod - local.base_pod_cidr_network_bits]...)
  )

}
