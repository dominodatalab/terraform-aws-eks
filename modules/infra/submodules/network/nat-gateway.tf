resource "aws_eip" "public" {
  for_each             = var.network.use_nat_gateway ? local.public_cidrs : {}
  network_border_group = var.region
  public_ipv4_pool     = "amazon"
  domain               = "vpc"
  tags = {
    "Name" = each.value.name
  }
}

resource "aws_nat_gateway" "ngw" {
  for_each          = var.network.use_nat_gateway ? local.public_cidrs : {}
  allocation_id     = aws_eip.public[each.key].allocation_id
  connectivity_type = "public"
  subnet_id         = aws_subnet.public[each.key].id
  tags = {
    "Name" = each.value.name
  }
  depends_on = [aws_internet_gateway.igw]
}
