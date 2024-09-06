locals {
  netapp_subnet_ids = startswith(var.storage.netapp.deployment_type, "MULTI") ? slice(local.private_subnet_ids, 0, 2) : [local.private_subnet_ids[0]]
}

resource "aws_security_group" "netapp" {
  count       = local.deploy_netapp ? 1 : 0
  name        = "${var.deploy_id}-netapp"
  description = "NetApp security group"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.deploy_id}-netapp"
  }
}

resource "aws_security_group_rule" "netapp_outbound" {
  count             = local.deploy_netapp ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.netapp[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "NETAPP outbound" # https://docs.netapp.com/us-en/bluexp-netapp-ontap/requirements/reference-security-groups-netapp.html#rules-for-netapp-for-ontap
}

locals {
  netapp_ontap_components_user = local.deploy_netapp ? {
    filesystem = "netappadmin"
    svm        = "vsadmin"
  } : {}
}

resource "random_password" "netapp" {
  for_each    = local.netapp_ontap_components_user
  length      = 16
  special     = false
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
}

resource "aws_secretsmanager_secret" "netapp" {
  for_each                = local.netapp_ontap_components_user
  name                    = "${var.deploy_id}-netapp-ontap-${each.key}"
  description             = "Credentials for ONTAP ${each.key}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "netapp" {
  for_each  = local.netapp_ontap_components_user
  secret_id = aws_secretsmanager_secret.netapp[each.key].id
  secret_string = jsonencode({
    username = each.value
    password = random_password.netapp[each.key].result
  })
}


data "aws_secretsmanager_secret_version" "netapp_creds" {
  for_each   = local.netapp_ontap_components_user
  secret_id  = aws_secretsmanager_secret.netapp[each.key].id
  depends_on = [aws_secretsmanager_secret_version.netapp]
}


resource "aws_fsx_ontap_file_system" "eks" {
  count                             = local.deploy_netapp ? 1 : 0
  storage_capacity                  = var.storage.netapp.storage_capacity
  subnet_ids                        = local.netapp_subnet_ids
  deployment_type                   = var.storage.netapp.deployment_type
  preferred_subnet_id               = local.netapp_subnet_ids[0]
  security_group_ids                = [aws_security_group.netapp[0].id]
  kms_key_id                        = local.kms_key_arn
  fsx_admin_password                = jsondecode(data.aws_secretsmanager_secret_version.netapp_creds["filesystem"].secret_string)["password"]
  throughput_capacity               = var.storage.netapp.throughput_capacity
  automatic_backup_retention_days   = var.storage.netapp.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.storage.netapp.daily_automatic_backup_start_time



  lifecycle {
    create_before_destroy = true
    ignore_changes        = [throughput_capacity]
  }

  tags = {
    "Name"   = var.deploy_id
    "Backup" = "true"
  }

  depends_on = [aws_secretsmanager_secret_version.netapp, aws_secretsmanager_secret.netapp]
}

resource "aws_fsx_ontap_storage_virtual_machine" "eks" {
  count                      = local.deploy_netapp ? 1 : 0
  file_system_id             = aws_fsx_ontap_file_system.eks[0].id
  name                       = "${var.deploy_id}-svm"
  root_volume_security_style = "UNIX"
  svm_admin_password         = random_password.netapp["svm"].result

  tags = {
    "Name" = "${var.deploy_id}-svm"
  }
}


resource "aws_cloudformation_stack" "fsx_ontap_scaling" {
  count         = var.storage.netapp.storage_capacity_autosizing.enabled ? 1 : 0
  name          = "${var.deploy_id}-fxn-storage-scaler"
  template_body = file("${path.module}/files/FSxOntapDynamicStorageScalingCLoudFormationTemplate.yaml")

  parameters = {
    FileSystemId                        = aws_fsx_ontap_file_system.eks[0].id
    LowFreeDataStorageCapacityThreshold = var.storage.netapp.storage_capacity_autosizing.threshold
    PercentIncrease                     = var.storage.netapp.storage_capacity_autosizing.percent_capacity_increase
    EmailAddress                        = var.storage.netapp.storage_capacity_autosizing.notification_email_address
  }

  on_failure = "DELETE"

  capabilities = ["CAPABILITY_NAMED_IAM"]
}
