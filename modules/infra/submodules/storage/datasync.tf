data "aws_subnet" "ds" {
  count = var.storage.efs.migrate_to_netapp.datasync.enabled ? 1 : 0
  id    = var.network_info.subnets.private[0].subnet_id
}

resource "aws_datasync_location_efs" "this" {
  count               = var.storage.efs.migrate_to_netapp.datasync.enabled ? 1 : 0
  efs_file_system_arn = aws_efs_file_system.eks[0].arn
  subdirectory        = "/"
  ec2_config {
    security_group_arns = [aws_security_group.efs[0].arn]
    subnet_arn          = data.aws_subnet.ds[0].arn
  }
}

resource "aws_datasync_location_fsx_ontap_file_system" "this" {
  count                       = var.storage.efs.migrate_to_netapp.datasync.enabled ? 1 : 0
  security_group_arns         = [aws_security_group.netapp[0].arn]
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
  count                    = var.storage.efs.migrate_to_netapp.datasync.enabled ? 1 : 0
  source_location_arn      = aws_datasync_location_efs.this[0].arn
  destination_location_arn = aws_datasync_location_fsx_ontap_file_system.this[0].arn

  schedule {
    schedule_expression = var.storage.efs.migrate_to_netapp.datasync.schedule
  }
}
