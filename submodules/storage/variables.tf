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
