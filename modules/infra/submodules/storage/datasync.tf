locals {
  create_ds = var.storage.netapp.migrate_from_efs.datasync.enabled
  datasync_security_group_rules = local.create_ds ? toset([
    {
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      description              = "Allow all traffic to DataSync"
      type                     = "ingress"
      source_security_group_id = aws_security_group.datasync[0].id
      security_group_id        = aws_security_group.efs[0].id
    },
    {
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      description              = "Allow all traffic to DataSync"
      type                     = "ingress"
      source_security_group_id = aws_security_group.datasync[0].id
      security_group_id        = aws_security_group.netapp[0].id
    },
  ]) : []
}

resource "aws_security_group" "datasync" {
  count  = local.create_ds ? 1 : 0
  name   = "${var.deploy_id}-datasync"
  vpc_id = var.network_info.vpc_id

  description = "Datasync security group"

  tags = {
    "Name" = "${var.deploy_id}-datasync"
  }
}

resource "aws_security_group_rule" "datasync_ingress" {
  for_each = local.datasync_security_group_rules

  security_group_id        = each.value.security_group_id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = each.value.description
  source_security_group_id = each.value.source_security_group_id
}

data "aws_subnet" "ds" {
  count = local.create_ds ? 1 : 0
  id    = var.network_info.subnets.private[0].subnet_id
}

resource "aws_datasync_location_efs" "this" {
  count               = local.create_ds ? 1 : 0
  efs_file_system_arn = aws_efs_file_system.eks[0].arn
  subdirectory        = "/"
  ec2_config {
    security_group_arns = [aws_security_group.datasync[0].arn]
    subnet_arn          = data.aws_subnet.ds[0].arn
  }
}

resource "aws_datasync_location_fsx_ontap_file_system" "this" {
  count                       = local.create_ds ? 1 : 0
  security_group_arns         = [aws_security_group.datasync[0].arn]
  storage_virtual_machine_arn = aws_fsx_ontap_storage_virtual_machine.eks[0].arn

  protocol {
    nfs {
      mount_options {
        version = "NFS3"
      }
    }
  }
}

resource "aws_datasync_task" "efs_to_netapp_migration" {
  count                    = local.create_ds ? 1 : 0
  source_location_arn      = aws_datasync_location_efs.this[0].arn
  destination_location_arn = aws_datasync_location_fsx_ontap_file_system.this[0].arn

  schedule {
    schedule_expression = var.storage.netapp.migrate_from_efs.datasync.schedule
  }
}
