variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}


variable "efs_access_point_path" {
  type        = string
  description = "Filesystem path for efs."
  default     = "/domino"

}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnets IDs to create EFS mount targets"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string

}

variable "s3_force_destroy_on_deletion" {
  description = "Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets"
  type        = bool
  default     = false
}

variable "ecr_force_destroy_on_deletion" {
  description = "Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories"
  type        = bool
  default     = false
}

variable "s3_kms_key" {
  description = "if set, use specified key for S3 buckets"
  type        = string
  default     = null
}

variable "ecr_kms_key" {
  description = "if set, use specified key for ECR repositories"
  type        = string
  default     = null
}

variable "efs_kms_key" {
  description = "if set, use specified key for EFS"
  type        = string
  default     = null
}

variable "efs_backup_vault_kms_key" {
  description = "if set, use specified key for EFS backup vault"
  type        = string
  default     = null
}

variable "create_efs_backup_vault" {
  description = "Create backup vault for EFS toggle."
  type        = bool
  default     = true
}

variable "efs_backup_vault_force_destroy" {
  description = "Toggle to allow automatic destruction of all backups when destroying."
  type        = bool
  default     = false
}

variable "efs_backup_schedule" {
  type        = string
  description = "Cron-style schedule for EFS backup vault (default: once a day at 12pm)"
  default     = "0 12 * * ? *"
}

variable "efs_backup_cold_storage_after" {
  type        = number
  description = "Move backup data to cold storage after this many days"
  default     = 35
}

variable "efs_backup_delete_after" {
  type        = number
  description = "Delete backup data after this many days"
  default     = 125
}
