variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{2,}(-[a-z0-9]+)*-\\w+-\\d+$", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1, us-iso-east-1."
  }
}

variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "kms_info" {
  description = <<EOF
    key_id  = KMS key id.
    key_arn = KMS key arn.
    enabled = KMS key is enabled
  EOF
  type = object({
    key_id  = string
    key_arn = string
    enabled = bool
  })
}

variable "storage" {
  description = <<EOF
    storage = {
      filesystem_type = File system type(netapp|efs|none)
      efs = {
        access_point_path = Filesystem path for efs.
        throughput_mode = EFS throughput mode (bursting, provisioned, or elastic).
        performance_mode = EFS performance mode (generalPurpose or maxIO).
        provisioned_throughput_in_mibps = Provisioned throughput in MiB/s (only used when throughput_mode is provisioned).
        backup_vault = {
          create        = Create backup vault for EFS toggle.
          force_destroy = Toggle to allow automatic destruction of all backups when destroying.
          backup = {
            schedule           = Cron-style schedule for EFS backup vault (default: once a day at 12pm).
            cold_storage_after = Move backup data to cold storage after this many days.
            delete_after       = Delete backup data after this many days.
          }
        }
      }
      netapp = {
        migrate_from_efs = {
          enabled =  When enabled, both EFS and NetApp resources will be provisioned simultaneously during the migration period.
          datasync = {
            enabled  = Toggle to enable AWS DataSync for automated data transfer from EFS to NetApp FSx.
            schedule = Cron-style schedule for the DataSync task, specifying how often the data transfer will occur (default: hourly).
            verify_mode = One of: POINT_IN_TIME_CONSISTENT, ONLY_FILES_TRANSFERRED, NONE.
          }
        }
        deployment_type = netapp ontap deployment type,('MULTI_AZ_1', 'MULTI_AZ_2', 'SINGLE_AZ_1', 'SINGLE_AZ_2')
        storage_capacity = Filesystem Storage capacity
        throughput_capacity = Filesystem throughput capacity
        automatic_backup_retention_days = How many days to keep backups
        daily_automatic_backup_start_time = Start time in 'HH:MM' format to initiate backups

        storage_capacity_autosizing = Options for the FXN automatic storage capacity increase, cloudformation template
          enabled                     = Enable automatic storage capacity increase.
          threshold                  = Used storage capacity threshold.
          percent_capacity_increase  = The percentage increase in storage capacity when used storage exceeds
                                       LowFreeDataStorageCapacityThreshold. Minimum increase is 10 %.
          notification_email_address = The email address for alarm notification.
        }
        volume = {
          create                     = Create a volume associated with the filesystem.
          name_suffix                = The suffix to name the volume
          storage_efficiency_enabled = Toggle storage_efficiency_enabled
          junction_path              = filesystem junction path
          size_in_megabytes          = The size of the volume
        }
        additional = Map of extra FSxN filesystems provisioned alongside the base one, for
                     resize-by-replacement and DR. Keys MUST be numeric (e.g. "1"): a key
                     renders the filesystem's 'Name' tag as '<deploy_id>-<key>' and its
                     credentials secrets as '<deploy_id>-netapp-ontap-<key>-<kind>', which is
                     what the FSxN migration tooling discovers by and what the Trident IRSA
                     secret wildcard already permits. Each entry accepts the same
                     deployment_type/storage_capacity/throughput_capacity/backup/autosizing
                     options as the base filesystem, plus:
          description  = Free-text note surfaced as a 'Description' tag.
          subnet_index = Index into the private subnets, for placing a DR filesystem in a
                         different AZ from the base one. Read the base filesystem's real
                         SubnetIds before setting this. The base filesystem ignores changes
                         to its subnets, so its live AZ may not be the one this index
                         resolves to now, and a mismatch pays cross-AZ transfer for the
                         entire baseline copy and cross-AZ NFS from compute thereafter.
          peering      = Open the ONTAP intercluster rules between this filesystem's security
                         group and the base one, for SnapMirror replication.
          volume       = As the base 'volume' block, but 'create' defaults to false because a
                         replication destination's volumes are created as DP volumes by the
                         migration tooling. Size it from the source volume as measured, not by
                         copying the base entry's value: the base one is a creation-time
                         setting that autosizing and out-of-band growth have usually left far
                         behind, and once 'active' names this filesystem its size becomes the
                         shared PVC's size.
        active = Which filesystem serves the cluster: "base" or a key of 'additional'. Selects
                 the filesystem reported in this module's netapp output, and therefore the one
                 Trident is pointed at. Confirm replication has caught up before changing this.
                 It deletes nothing, so no plan or policy gate can catch a premature flip, and
                 pointing Trident at a filesystem the data has not finished landing on is an
                 immediate outage.
        retire_base = Destroy the base filesystem. Requires 'active' to name an additional
                      filesystem, so the filesystem currently serving the cluster cannot be
                      destroyed. Terraform manages one volume on that filesystem; volumes
                      Trident provisioned are invisible to this state, and FSx refuses to
                      delete an SVM that still holds non-root volumes. Clear them from the
                      base SVM first, or the apply dies part way through the destroy. Those are
                      customer data volumes, so take final backups of them as part of that
                      step: this module's own volume is the only one its backup settings cover.
      }
      s3 = {
        force_destroy_on_deletion = Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets.
      }
      ecr = {
        force_destroy_on_deletion = Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories.
      }
      enable_remote_backup = Enable tagging required for cross-account backups
      costs_enabled = Determines whether to provision domino cost related infrastructures, ie, long term storage
      workspace_audit = {
        enabled = Determines whether to provision workspace audit buckets
        events_bucket_name = workspace-events bucket name
        events_archive_bucket_name = workspace-events-archive bucket name
      }
    }
  }
  EOF
  type = object({
    filesystem_type = string
    efs = optional(object({
      access_point_path               = optional(string)
      throughput_mode                 = optional(string)
      performance_mode                = optional(string)
      provisioned_throughput_in_mibps = optional(string)
      backup_vault = optional(object({
        create        = optional(bool)
        force_destroy = optional(bool)
        backup = optional(object({
          schedule           = optional(string)
          cold_storage_after = optional(number)
          delete_after       = optional(number)
        }))
      }))
    }))
    netapp = optional(object({
      migrate_from_efs = optional(object({
        enabled = optional(bool)
        datasync = optional(object({
          enabled     = optional(bool)
          target      = optional(string)
          schedule    = optional(string)
          verify_mode = optional(string)
        }))
      }))
      deployment_type                   = optional(string)
      storage_capacity                  = optional(number)
      throughput_capacity               = optional(number)
      automatic_backup_retention_days   = optional(number)
      daily_automatic_backup_start_time = optional(string)
      storage_capacity_autosizing = optional(object({
        enabled                    = optional(bool)
        threshold                  = optional(number)
        percent_capacity_increase  = optional(number)
        notification_email_address = optional(string)
      }))
      volume = optional(object({
        name_suffix                = optional(string)
        storage_efficiency_enabled = optional(bool)
        create                     = optional(bool)
        junction_path              = optional(string)
        size_in_megabytes          = optional(number)
      }))
      # Additional filesystems alongside the base one, for resize-by-replacement and DR.
      # Keys must be numeric: they render the "Name" tag as "<deploy_id>-<key>" and the
      # credentials secrets as "<deploy_id>-netapp-ontap-<key>-<kind>", which is the
      # naming the FSxN migration tooling discovers by and which the Trident IRSA policy
      # wildcard "<deploy_id>-netapp-ontap-*" already covers.
      additional = optional(map(object({
        description                       = optional(string)
        deployment_type                   = optional(string)
        storage_capacity                  = optional(number)
        throughput_capacity               = optional(number)
        automatic_backup_retention_days   = optional(number)
        daily_automatic_backup_start_time = optional(string)
        subnet_index                      = optional(number)
        peering                           = optional(bool)
        storage_capacity_autosizing = optional(object({
          enabled                    = optional(bool)
          threshold                  = optional(number)
          percent_capacity_increase  = optional(number)
          notification_email_address = optional(string)
        }))
        volume = optional(object({
          name_suffix       = optional(string)
          create            = optional(bool)
          junction_path     = optional(string)
          size_in_megabytes = optional(number)
        }))
      })))
      active      = optional(string)
      retire_base = optional(bool)
    }))
    s3 = optional(object({
      create                    = optional(bool)
      force_destroy_on_deletion = optional(bool)
    }))
    ecr = optional(object({
      create                    = optional(bool)
      force_destroy_on_deletion = optional(bool)
    }))
    enable_remote_backup = optional(bool)
    costs_enabled        = optional(bool)
    workspace_audit = optional(object({
      enabled                    = optional(bool)
      events_bucket_name         = optional(string)
      events_archive_bucket_name = optional(string)
    }))
  })
  validation {
    condition     = contains(["efs", "netapp", "none"], var.storage.filesystem_type)
    error_message = "Invalid filesystem type: only 'efs' and 'netapp' are supported for Filesystem storage."
  }

  validation {
    condition     = var.storage.filesystem_type != "netapp" || (var.storage.filesystem_type == "netapp" && contains(["MULTI_AZ_1", "MULTI_AZ_2", "SINGLE_AZ_1", "SINGLE_AZ_2"], var.storage.netapp.deployment_type))
    error_message = "Invalid 'deployment_type' for netapp filesystem, supported deployment types are 'MULTI_AZ_1', 'MULTI_AZ_2', 'SINGLE_AZ_1', and 'SINGLE_AZ_2'."
  }

  validation {
    condition     = !var.storage.netapp.migrate_from_efs.datasync.enabled || (var.storage.netapp.migrate_from_efs.datasync.enabled && var.storage.netapp.migrate_from_efs.enabled)
    error_message = "Expected `storage.netapp.migrate_from_efs.enabled` if `storage.netapp.migrate_from_efs.datasync.enabled`"
  }

  validation {
    condition     = alltrue([for k in keys(coalesce(var.storage.netapp.additional, {})) : can(regex("^[0-9]+$", k))])
    error_message = "Keys of `storage.netapp.additional` must be numeric (e.g. \"1\"): the migration tooling discovers a filesystem's credentials secrets by matching its `Name` tag against '^(.+)-([0-9]+)$'."
  }

  validation {
    condition = alltrue([
      for k, v in coalesce(var.storage.netapp.additional, {}) :
      v.deployment_type == null || contains(["MULTI_AZ_1", "MULTI_AZ_2", "SINGLE_AZ_1", "SINGLE_AZ_2"], coalesce(v.deployment_type, ""))
    ])
    error_message = "Invalid 'deployment_type' in `storage.netapp.additional`, supported deployment types are 'MULTI_AZ_1', 'MULTI_AZ_2', 'SINGLE_AZ_1', and 'SINGLE_AZ_2'."
  }

  validation {
    condition = alltrue([
      for k, v in coalesce(var.storage.netapp.additional, {}) : coalesce(v.subnet_index, 0) >= 0
    ])
    error_message = "`storage.netapp.additional[*].subnet_index` must not be negative."
  }

  validation {
    condition = alltrue([
      for k, v in coalesce(var.storage.netapp.additional, {}) :
      coalesce(v.storage_capacity, 1024) >= 1024 && coalesce(v.storage_capacity, 1024) <= 1048576
    ])
    error_message = "`storage.netapp.additional[*].storage_capacity` must be between 1024 and 1048576 GiB. FSx for ONTAP will not create a filesystem below 1024 GiB, so that is also the floor for how far a filesystem can be right-sized by replacement."
  }

  # The autosizing values are handed to the CloudFormation scaling stack, which declares
  # PercentIncrease as MinValue 10 / MaxValue 100. Without these an out-of-range value is
  # accepted at plan and fails inside CloudFormation at apply, where the stack is created with
  # on_failure = DELETE.
  validation {
    condition = alltrue([
      for a in concat(
        [try(var.storage.netapp.storage_capacity_autosizing, null)],
        [for k, v in coalesce(var.storage.netapp.additional, {}) : try(v.storage_capacity_autosizing, null)],
        ) : a == null || (
        coalesce(try(a.percent_capacity_increase, null), 30) >= 10
        && coalesce(try(a.percent_capacity_increase, null), 30) <= 100
      )
    ])
    error_message = "`storage_capacity_autosizing.percent_capacity_increase` must be between 10 and 100, on the base filesystem and on every entry of `storage.netapp.additional`. FSx's scaling template rejects anything outside that range."
  }

  # Unlike the percent, this bound is ours: the CloudFormation template puts no MinValue or
  # MaxValue on the threshold. 100 would mean the alarm can never clear and 0 would mean it never
  # fires, so both ends are excluded.
  validation {
    condition = alltrue([
      for a in concat(
        [try(var.storage.netapp.storage_capacity_autosizing, null)],
        [for k, v in coalesce(var.storage.netapp.additional, {}) : try(v.storage_capacity_autosizing, null)],
        ) : a == null || (
        coalesce(try(a.threshold, null), 70) >= 1
        && coalesce(try(a.threshold, null), 70) <= 99
      )
    ])
    error_message = "`storage_capacity_autosizing.threshold` must be between 1 and 99 percent, on the base filesystem and on every entry of `storage.netapp.additional`."
  }

  validation {
    condition = (
      coalesce(var.storage.netapp.active, "base") == "base" ||
      contains(keys(coalesce(var.storage.netapp.additional, {})), coalesce(var.storage.netapp.active, "base"))
    )
    error_message = "`storage.netapp.active` must be \"base\" or a key of `storage.netapp.additional`."
  }

  validation {
    condition     = !coalesce(var.storage.netapp.retire_base, false) || coalesce(var.storage.netapp.active, "base") != "base"
    error_message = "`storage.netapp.retire_base` requires `storage.netapp.active` to point at an additional filesystem: the filesystem currently serving the cluster cannot be destroyed."
  }

  # The EFS -> NetApp migration wires DataSync and the legacy EFS filesystem directly to the
  # base NetApp filesystem, so the base one cannot be retired while that migration is in play.
  validation {
    condition     = !coalesce(var.storage.netapp.retire_base, false) || !var.storage.netapp.migrate_from_efs.enabled
    error_message = "`storage.netapp.retire_base` cannot be combined with `storage.netapp.migrate_from_efs.enabled`: finish the EFS migration before retiring the base filesystem."
  }
}

variable "network_info" {
  description = <<EOF
    id = VPC ID.
    subnets = {
      public = List of public Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      private = List of private Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet id
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      pod = List of pod Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
    }
  EOF
  type = object({
    vpc_id = string
    subnets = object({
      public = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
      private = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      pod = optional(list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      })), [])
    })
  })
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}
