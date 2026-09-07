locals {
  netapp_subnet_ids = startswith(var.storage.netapp.deployment_type, "MULTI") ? sort(slice(local.private_subnet_ids, 0, 2)) : sort([local.private_subnet_ids[0]])

  # Same placement rule as the base filesystem, except a SINGLE_AZ additional filesystem can
  # be pinned to a specific private subnet via subnet_index (a DR replica usually wants a
  # different AZ from the base one). An out-of-range index yields an empty list, which the
  # precondition on aws_fsx_ontap_file_system.netapp_additional reports.
  netapp_additional_subnet_ids = {
    for k, v in local.netapp_additional : k => (
      startswith(v.deployment_type, "MULTI")
      ? sort(slice(local.private_subnet_ids, 0, 2))
      : compact([try(local.private_subnet_ids[v.subnet_index], "")])
    )
  }

  # Additional filesystems that replicate to or from the base one. SnapMirror needs the two
  # filesystems' security groups to admit each other.
  netapp_peers = {
    for k, v in local.netapp_additional : k => v
    if v.peering && local.deploy_netapp_base
  }
}

resource "aws_security_group" "netapp" {
  count       = local.deploy_netapp_base ? 1 : 0
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
  count             = local.deploy_netapp_base ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.netapp[0].id
  # trivy:ignore:AWS-0104 NetApp ONTAP requires unrestricted egress per https://docs.netapp.com/us-en/bluexp-netapp-ontap/requirements/reference-security-groups-netapp.html#rules-for-netapp-for-ontap
  cidr_blocks = ["0.0.0.0/0"]
  description = "NETAPP outbound" # https://docs.netapp.com/us-en/bluexp-netapp-ontap/requirements/reference-security-groups-netapp.html#rules-for-netapp-for-ontap
}

locals {
  netapp_base_components_user = local.deploy_netapp_base ? {
    filesystem = "fsxadmin"
    svm        = "vsadmin"
  } : {}

  # Composite keys ("<fs-key>-filesystem", "<fs-key>-svm") so that the secret naming below
  # renders "<deploy_id>-netapp-ontap-<fs-key>-<kind>". That is the name the FSxN migration
  # tooling discovers a filesystem's credentials by, and it stays inside the Trident IRSA
  # policy's "<deploy_id>-netapp-ontap-*" wildcard so no IAM change is needed.
  netapp_additional_components_user = {
    for pair in flatten([
      for k, v in local.netapp_additional : [
        { key = "${k}-filesystem", user = "fsxadmin" },
        { key = "${k}-svm", user = "vsadmin" },
      ]
    ]) : pair.key => pair.user
  }

  netapp_ontap_components_user = merge(
    local.netapp_base_components_user,
    local.netapp_additional_components_user,
  )

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
  count                             = local.deploy_netapp_base ? 1 : 0
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
  count                      = local.deploy_netapp_base ? 1 : 0
  file_system_id             = aws_fsx_ontap_file_system.eks[0].id
  name                       = "${var.deploy_id}-svm"
  root_volume_security_style = "UNIX"
  svm_admin_password         = random_password.netapp["svm"].result

  tags = {
    "Name" = "${var.deploy_id}-svm"
  }
}

resource "aws_fsx_ontap_volume" "eks" {
  count                      = local.deploy_netapp_base && var.storage.netapp.volume.create ? 1 : 0
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
  count         = local.deploy_netapp_base && var.storage.netapp.storage_capacity_autosizing.enabled ? 1 : 0
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


## Additional filesystems (storage.netapp.additional), for resize-by-replacement and DR.
## These are provisioned alongside the base filesystem; `storage.netapp.active` selects which
## one this module reports in its netapp output, and therefore which one Trident is pointed at.

resource "aws_security_group" "netapp_additional" {
  for_each    = local.netapp_additional
  name        = "${var.deploy_id}-netapp-${each.key}"
  description = "NetApp security group (${each.key})"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.deploy_id}-netapp-${each.key}"
  }
}

resource "aws_security_group_rule" "netapp_additional_outbound" {
  for_each          = local.netapp_additional
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.netapp_additional[each.key].id
  # trivy:ignore:AWS-0104 NetApp ONTAP requires unrestricted egress per https://docs.netapp.com/us-en/bluexp-netapp-ontap/requirements/reference-security-groups-netapp.html#rules-for-netapp-for-ontap
  cidr_blocks = ["0.0.0.0/0"]
  description = "NETAPP ${each.key} outbound" # https://docs.netapp.com/us-en/bluexp-netapp-ontap/requirements/reference-security-groups-netapp.html#rules-for-netapp-for-ontap
}

# Reciprocal all-traffic rules between the base and the replica, sourced by security group.
# ONTAP cluster and SVM peering need both directions; the migration tooling verifies exactly
# this shape (an ingress rule with IpProtocol "-1" naming the peer security group), so
# declaring it here keeps that check passing without out-of-band security group edits.
resource "aws_security_group_rule" "netapp_peering_to_additional" {
  for_each                 = local.netapp_peers
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.netapp_additional[each.key].id
  source_security_group_id = aws_security_group.netapp[0].id
  description              = "NETAPP ${each.key} inbound from the base filesystem (SnapMirror)"
}

resource "aws_security_group_rule" "netapp_peering_to_base" {
  for_each                 = local.netapp_peers
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.netapp[0].id
  source_security_group_id = aws_security_group.netapp_additional[each.key].id
  description              = "NETAPP inbound from additional filesystem ${each.key} (SnapMirror)"
}

resource "aws_fsx_ontap_file_system" "netapp_additional" {
  for_each                          = local.netapp_additional
  storage_capacity                  = each.value.storage_capacity
  subnet_ids                        = local.netapp_additional_subnet_ids[each.key]
  deployment_type                   = each.value.deployment_type
  preferred_subnet_id               = local.netapp_additional_subnet_ids[each.key][0]
  security_group_ids                = [aws_security_group.netapp_additional[each.key].id]
  kms_key_id                        = local.kms_key_arn
  fsx_admin_password                = jsondecode(data.aws_secretsmanager_secret_version.netapp_creds["${each.key}-filesystem"].secret_string)["password"]
  throughput_capacity               = each.value.throughput_capacity
  automatic_backup_retention_days   = each.value.automatic_backup_retention_days
  daily_automatic_backup_start_time = each.value.daily_automatic_backup_start_time

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [storage_capacity, preferred_subnet_id, subnet_ids]

    precondition {
      condition     = length(local.netapp_additional_subnet_ids[each.key]) > 0
      error_message = "`subnet_index` is out of range for the private subnets available in this VPC."
    }
  }

  # The "Name" tag is the handle the FSxN migration tooling resolves a filesystem by.
  tags = merge({
    "Name"   = "${var.deploy_id}-${each.key}"
    "Backup" = "true"
    }, each.value.description != "" ? {
    "Description" = each.value.description
  } : {})

  depends_on = [aws_secretsmanager_secret_version.netapp, aws_secretsmanager_secret.netapp]
}

resource "aws_fsx_ontap_storage_virtual_machine" "netapp_additional" {
  for_each       = local.netapp_additional
  file_system_id = aws_fsx_ontap_file_system.netapp_additional[each.key].id
  # Suffixed rather than reusing the base SVM name: ONTAP SVM peering, which SnapMirror
  # requires, cannot disambiguate two peered SVMs sharing a name.
  name                       = "${var.deploy_id}-svm-${each.key}"
  root_volume_security_style = "UNIX"
  svm_admin_password         = random_password.netapp["${each.key}-svm"].result

  tags = {
    "Name" = "${var.deploy_id}-svm-${each.key}"
  }
}

# Off by default: a replication destination's data volumes are created as DP (mirror) volumes
# by the migration tooling, and a Terraform-managed RW volume would collide with them.
resource "aws_fsx_ontap_volume" "netapp_additional" {
  for_each                   = { for k, v in local.netapp_additional : k => v if v.volume.create }
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.netapp_additional[each.key].id
  name                       = replace("${var.deploy_id}_${each.value.volume.name_suffix}", "/[^a-zA-z0-9_]/", "_")
  junction_path              = each.value.volume.junction_path
  size_in_megabytes          = each.value.volume.size_in_megabytes
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

resource "aws_cloudformation_stack" "fsx_ontap_scaling_additional" {
  for_each      = { for k, v in local.netapp_additional : k => v if v.storage_capacity_autosizing.enabled }
  name          = "${var.deploy_id}-${each.key}-fxn-storage-scaler"
  template_body = file("${path.module}/files/FSxOntapDynamicStorageScalingCLoudFormationTemplate.yaml")

  parameters = {
    FileSystemId                        = aws_fsx_ontap_file_system.netapp_additional[each.key].id
    LowFreeDataStorageCapacityThreshold = each.value.storage_capacity_autosizing.threshold
    PercentIncrease                     = each.value.storage_capacity_autosizing.percent_capacity_increase
    EmailAddress                        = each.value.storage_capacity_autosizing.notification_email_address
  }

  on_failure = "DELETE"

  capabilities = ["CAPABILITY_NAMED_IAM"]
}

locals {
  # Per-filesystem descriptions, all in the shape this module has always reported for netapp,
  # so that whichever one `active` selects is a drop-in for existing consumers.
  netapp_base_info = local.deploy_netapp_base ? {
    svm = {
      name             = aws_fsx_ontap_storage_virtual_machine.eks[0].name
      management_ip    = one(aws_fsx_ontap_storage_virtual_machine.eks[0].endpoints[0].management[0].ip_addresses)
      nfs_ip           = one(aws_fsx_ontap_storage_virtual_machine.eks[0].endpoints[0].nfs[0].ip_addresses)
      creds_secret_arn = aws_secretsmanager_secret.netapp["svm"].arn
    }
    filesystem = { id = aws_fsx_ontap_file_system.eks[0].id, security_group_id = aws_security_group.netapp[0].id }
    volume = {
      name = var.storage.netapp.volume.create ? aws_fsx_ontap_volume.eks[0].name : replace("${var.deploy_id}_${var.storage.netapp.volume.name_suffix}", "/[^a-zA-z0-9_]/", "_")
    }
  } : null

  netapp_additional_info = {
    for k, v in local.netapp_additional : k => {
      svm = {
        name             = aws_fsx_ontap_storage_virtual_machine.netapp_additional[k].name
        management_ip    = one(aws_fsx_ontap_storage_virtual_machine.netapp_additional[k].endpoints[0].management[0].ip_addresses)
        nfs_ip           = one(aws_fsx_ontap_storage_virtual_machine.netapp_additional[k].endpoints[0].nfs[0].ip_addresses)
        creds_secret_arn = aws_secretsmanager_secret.netapp["${k}-svm"].arn
      }
      filesystem = { id = aws_fsx_ontap_file_system.netapp_additional[k].id, security_group_id = aws_security_group.netapp_additional[k].id }
      volume = {
        # Where Terraform does not create the volume, the migration tooling creates the
        # destination volume under the same name as the source it mirrors, so report that.
        name = v.volume.create ? aws_fsx_ontap_volume.netapp_additional[k].name : replace("${var.deploy_id}_${v.volume.name_suffix}", "/[^a-zA-z0-9_]/", "_")
      }
    }
  }

  # The filesystem serving the cluster. `active` is validated to be "base" or a key of
  # storage.netapp.additional; the try() only covers `active` naming an additional filesystem
  # on a deployment where netapp is not deployed at all, where there is nothing to report.
  netapp_info = local.netapp_active == "base" ? local.netapp_base_info : try(local.netapp_additional_info[local.netapp_active], null)
}
