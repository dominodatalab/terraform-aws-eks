locals {
  capacity_reservations = merge(flatten([
    for ng_name, ng in var.instance_capacity : [
      for az_id in ng.availability_zone_ids : {
        for type in ng.instance_types : "${type}-${az_id}" => {
          capacity      = ng.capacity
          instance_type = type
          az            = data.aws_availability_zone.zone_ids[az_id].name
        }
      }
    ]
  ])...)
  zone_ids = toset(flatten([for ng in var.instance_capacity :
    ng.availability_zone_ids
  ]))

  instance_types = toset([for cr in local.capacity_reservations : cr.instance_type])
}

data "aws_availability_zone" "zone_ids" {
  for_each = local.zone_ids
  zone_id  = each.key
}


data "aws_ec2_instance_type_offerings" "this" {
  for_each = local.instance_types

  filter {
    name   = "instance-type"
    values = [each.key]
  }

  location_type = "availability-zone"
}


resource "aws_ec2_capacity_reservation" "this" {
  for_each          = local.capacity_reservations
  instance_type     = each.value.instance_type
  instance_platform = "Linux/UNIX"
  availability_zone = each.value.az
  instance_count    = each.value.capacity

  lifecycle {
    precondition {
      condition     = contains(data.aws_ec2_instance_type_offerings.this[each.value.instance_type].locations, each.value.az)
      error_message = <<-EOM
        Instance type ${each.value.instance_type} is NOT available in availability_zone ${each.value.az}.
        available = ${jsonencode(data.aws_ec2_instance_type_offerings.this[each.value.instance_type].locations)}
      EOM
    }
  }
}

resource "terraform_data" "describe_capacity_reservation" {
  for_each = aws_ec2_capacity_reservation.this

  provisioner "local-exec" {
    command     = <<EOT
      aws ec2 describe-capacity-reservations --capacity-reservation-ids ${each.value.id} --region ${var.region}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [aws_ec2_capacity_reservation.this]
}
