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

variable "subnets" {
  type = list(object({
    name       = string
    id         = string
    cidr_block = string
  }))
  description = "List of subnet ids to create EFS mount targets"
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

variable "s3_encryption_use_sse_kms_key" {
  description = "if true use 'aws:kms' else 'AES256' for the s3 server-side-encryption."
  type        = bool
  default     = false
}

variable "roles" {
  description = "List of roles to grant s3 permissions"
  type        = list(any)
}
