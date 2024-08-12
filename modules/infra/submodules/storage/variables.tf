variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af|il)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
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
      filesystem_type = File system type(fsx|efs)
      efs = {
        access_point_path = Filesystem path for efs.
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
      fsx = {
        deployment_type = fsx ontap deployment type,('MULTI_AZ_1', 'MULTI_AZ_2', 'SINGLE_AZ_1', 'SINGLE_AZ_2')
        storage_capacity = Filesystem Storage capacity
        throughput_capacity = Filesystem throughput capacity
      }
      s3 = {
        force_destroy_on_deletion = Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets.
      }
      ecr = {
        force_destroy_on_deletion = Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories.
      }
      enable_remote_backup = Enable tagging required for cross-account backups
      costs_enabled = Determines whether to provision domino cost related infrastructures, ie, long term storage
    }
  }
  EOF
  type = object({
    filesystem_type = string
    efs = optional(object({
      access_point_path = optional(string)
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
    fsx = optional(object({
      deployment_type     = optional(string)
      storage_capacity    = optional(number)
      throughput_capacity = optional(number)
    }))
    s3 = optional(object({
      force_destroy_on_deletion = optional(bool)
    }))
    ecr = optional(object({
      force_destroy_on_deletion = optional(bool)
    }))
    enable_remote_backup = optional(bool)
    costs_enabled        = optional(bool)
  })
  validation {
    condition     = contains(["efs", "fsx"], var.storage.filesystem_type)
    error_message = "Invalid filesystem type: only 'efs' and 'fsx' are supported for Filesystem storage."
  }

  validation {
    condition     = var.storage.filesystem_type != "fsx" || (var.storage.filesystem_type == "fsx" && contains(["MULTI_AZ_1", "MULTI_AZ_2", "SINGLE_AZ_1", "SINGLE_AZ_2"], var.storage.fsx.deployment_type))
    error_message = "Invalid 'deployment_type' for fsx filesystem, supported deployment types are 'MULTI_AZ_1', 'MULTI_AZ_2', 'SINGLE_AZ_1', and 'SINGLE_AZ_2'."
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
        subnet_id = Subnet ud
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
