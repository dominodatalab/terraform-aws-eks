locals {
  netapp_subnet_ids = startswith(var.storage.netapp.deployment_type, "MULTI") ? sort(slice(local.private_subnet_ids, 0, 2)) : sort([local.private_subnet_ids[0]])
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
    filesystem = "fsxadmin"
    svm        = "vsadmin"
  } : {}

  netapp_secret_names = { for k, v in local.netapp_ontap_components_user : k => "${var.deploy_id}-netapp-ontap-${k}" }
}

resource "random_password" "netapp" {
  for_each    = local.netapp_ontap_components_user
  length      = 16
  special     = false
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
}


resource "terraform_data" "secrets_cleanup" {
  for_each = local.netapp_secret_names

  input = {
    AWS_USE_FIPS_ENDPOINT = tostring(var.use_fips_endpoint)
    secret_name           = each.value
    AWS_REGION            = var.region
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<-EOF
      set -euo pipefail

      sleep_duration=10
      max_retries=30

      secret_id=$(aws secretsmanager list-secrets \
        --include-planned-deletion \
        --query "SecretList[?Name=='${self.input.secret_name}'].SecretId" \
        --output text)

      if [ -z "$secret_id" ]; then
        echo "Secret with name '${self.input.secret_name}' not found. Skipping deletion."
        exit 0
      fi

      delete_secret() {
        echo "Force deleting secret $secret_id"
        aws secretsmanager delete-secret --secret-id "$secret_id" --force-delete-without-recovery || true
      }

      secret_exists() {
        aws secretsmanager describe-secret --secret-id "$secret_id" --query 'Name' --output text > /dev/null 2>&1
      }

      for i in $(seq 1 $max_retries); do
        if ! secret_exists; then
          echo "Secret $secret_id successfully deleted."
          exit 0
        fi

        delete_secret

        echo "Waiting for secret deletion... attempt $i"
        sleep "$sleep_duration"
      done

      echo "Timed out waiting for secret deletion."
      exit 1
    EOF
    interpreter = ["bash", "-c"]
    environment = {
      AWS_USE_FIPS_ENDPOINT = self.input.AWS_USE_FIPS_ENDPOINT
      AWS_REGION            = self.input.AWS_REGION
    }
  }
}


resource "aws_secretsmanager_secret" "netapp" {
  for_each                = local.netapp_secret_names
  name                    = each.value
  description             = "Credentials for ONTAP ${each.key}"
  recovery_window_in_days = 0
  depends_on              = [terraform_data.secrets_cleanup]
}


resource "aws_secretsmanager_secret_version" "netapp" {
  for_each  = local.netapp_secret_names
  secret_id = aws_secretsmanager_secret.netapp[each.key].id
  secret_string = jsonencode({
    username = local.netapp_ontap_components_user[each.key]
    password = random_password.netapp[each.key].result
  })
}

## Mitigating propagation delay: Error: reading Secrets Manager Secret Version ...couldn't find resource

resource "terraform_data" "wait_for_secrets" {
  for_each = aws_secretsmanager_secret.netapp
  provisioner "local-exec" {
    command     = <<-EOF
      set -x -o pipefail

      sleep_duration=10
      max_retries=30
      required_secret="${each.value.name}"

      check_secrets() {
        secrets=$(aws secretsmanager list-secrets --region ${var.region} --query 'SecretList[?starts_with(Name, `${var.deploy_id}`)].Name' --output text)

        if ! grep -q "$required_secret" <<< "$secrets"; then
            return 1
        fi

        return 0
      }

      for i in $(seq 1 $max_retries); do
        if check_secrets; then
          exit 0
        fi

        echo "Waiting for secrets... attempt $i"
        sleep "$sleep_duration"
      done

      echo "Timed out waiting for secrets."
      exit 1
    EOF
    interpreter = ["bash", "-c"]
    environment = {
      AWS_USE_FIPS_ENDPOINT = tostring(var.use_fips_endpoint)
    }
  }

  depends_on = [aws_secretsmanager_secret.netapp]
}


data "aws_secretsmanager_secret_version" "netapp_creds" {
  for_each   = local.netapp_secret_names
  secret_id  = aws_secretsmanager_secret.netapp[each.key].id
  depends_on = [terraform_data.wait_for_secrets]
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
    ignore_changes        = [storage_capacity, preferred_subnet_id, subnet_ids]
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

resource "aws_fsx_ontap_volume" "eks" {
  count                      = local.deploy_netapp && var.storage.netapp.volume.create ? 1 : 0
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.eks[0].id
  name                       = replace("${var.deploy_id}_${var.storage.netapp.volume.name_suffix}", "/[^a-zA-z0-9_]/", "_")
  junction_path              = var.storage.netapp.volume.junction_path
  size_in_megabytes          = var.storage.netapp.volume.size_in_megabytes
  storage_efficiency_enabled = true
  security_style             = "UNIX"
  ontap_volume_type          = "RW"
  copy_tags_to_backups       = true
  volume_style               = "FLEXVOL"
  tags                       = local.backup_tagging

  lifecycle {
    ignore_changes = [name, size_in_megabytes] # This volume is meant to be managed by the trident operator after initial creation.
  }
}


resource "aws_cloudformation_stack" "fsx_ontap_scaling" {
  count         = local.deploy_netapp && var.storage.netapp.storage_capacity_autosizing.enabled ? 1 : 0
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
