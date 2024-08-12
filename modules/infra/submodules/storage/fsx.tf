locals {
  fsx_subnet_ids = startswith(var.storage.fsx.deployment_type, "MULTI") ? slice(local.private_subnet_ids, 0, 2) : [local.private_subnet_ids[0]]
}

resource "aws_security_group" "fsx" {
  count       = local.deploy_fsx ? 1 : 0
  name        = "${var.deploy_id}-fsx"
  description = "FSx security group"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.deploy_id}-fsx"
  }
}

resource "aws_security_group_rule" "fsx_outbound" {
  count             = local.deploy_fsx ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsx[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "FSX outbound" # https://docs.netapp.com/us-en/bluexp-fsx-ontap/requirements/reference-security-groups-fsx.html#rules-for-fsx-for-ontap
}

locals {
  fsx_ontap_components_user = local.deploy_fsx ? {
    filesystem = "fsxadmin"
    svm        = "vsadmin"
  } : {}
}

resource "random_password" "fsx" {
  for_each    = local.fsx_ontap_components_user
  length      = 16
  special     = false
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
}

resource "aws_secretsmanager_secret" "fsx" {
  for_each    = local.fsx_ontap_components_user
  name        = "${var.deploy_id}-fsx-ontap-${each.key}"
  kms_key_id  = local.kms_key_arn
  description = "Credentials for ONTAP ${each.key}"
}

resource "aws_secretsmanager_secret_version" "fsx" {
  for_each  = local.fsx_ontap_components_user
  secret_id = aws_secretsmanager_secret.fsx[each.key].id
  secret_string = jsonencode({
    username = each.value
    password = random_password.fsx[each.key].result
  })
}


data "aws_secretsmanager_secret_version" "fsx_creds" {
  for_each   = local.fsx_ontap_components_user
  secret_id  = aws_secretsmanager_secret.fsx[each.key].id
  depends_on = [aws_secretsmanager_secret_version.fsx]
}


resource "aws_fsx_ontap_file_system" "eks" {
  count                             = local.deploy_fsx ? 1 : 0
  storage_capacity                  = var.storage.fsx.storage_capacity
  subnet_ids                        = local.fsx_subnet_ids
  deployment_type                   = var.storage.fsx.deployment_type
  preferred_subnet_id               = local.fsx_subnet_ids[0]
  security_group_ids                = [aws_security_group.fsx[0].id]
  kms_key_id                        = local.kms_key_arn
  fsx_admin_password                = jsondecode(data.aws_secretsmanager_secret_version.fsx_creds["filesystem"].secret_string)["password"]
  throughput_capacity               = var.storage.fsx.throughput_capacity
  automatic_backup_retention_days   = var.storage.fsx.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.storage.fsx.daily_automatic_backup_start_time



  lifecycle {
    create_before_destroy = true
    ignore_changes        = [throughput_capacity] ## TODO: will keep trying to update ~ throughput_capacity = 0 -> 1536
  }

  tags = {
    "Name"   = var.deploy_id
    "Backup" = "true"
  }

  depends_on = [aws_secretsmanager_secret_version.fsx, aws_secretsmanager_secret.fsx]
}

resource "aws_fsx_ontap_storage_virtual_machine" "eks" {
  count                      = local.deploy_fsx ? 1 : 0
  file_system_id             = aws_fsx_ontap_file_system.eks[0].id
  name                       = "${var.deploy_id}-svm"
  root_volume_security_style = "UNIX"
  svm_admin_password         = random_password.fsx["svm"].result

  tags = {
    "Name" = "${var.deploy_id}-svm"
  }
}
