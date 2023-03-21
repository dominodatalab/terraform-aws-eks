resource "aws_route_table" "public" {
  for_each = local.public_cidrs
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  vpc_id = aws_vpc.this[0].id
  tags = {
    "Name" = each.value.name,
  }
}

resource "aws_route_table_association" "public" {
  for_each       = local.public_cidrs
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

locals {
  private_public_map = zipmap(keys(local.private_cidrs), keys(local.public_cidrs))
}

resource "aws_route_table" "private" {
  for_each = local.private_cidrs
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[local.private_public_map[each.key]].id
  }
  vpc_id = aws_vpc.this[0].id
  tags = {
    "Name" = each.value.name,
  }
}

resource "aws_route_table_association" "private" {
  for_each       = local.private_cidrs
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

locals {
  pod_public_map = var.network.use_pod_cidr ? zipmap(keys(local.pod_cidrs), keys(local.public_cidrs)) : {}
}

resource "aws_route_table" "pod" {
  for_each = local.pod_cidrs
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[local.pod_public_map[each.key]].id
  }
  vpc_id = aws_vpc.this[0].id
  tags = {
    "Name" = each.value.name,
  }
}

resource "aws_route_table_association" "pod" {
  for_each       = local.pod_cidrs
  subnet_id      = aws_subnet.pod[each.key].id
  route_table_id = aws_route_table.pod[each.key].id
}
