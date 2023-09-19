resource "aws_internet_gateway" "igw" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags = {
    "Name" = "${var.deploy_id}-domino-igw"
  }
}
