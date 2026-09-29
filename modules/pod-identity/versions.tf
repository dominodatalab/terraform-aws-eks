terraform {
  # 1.3 for optional() attribute defaults in filetask_objectstore, and for the precondition
  # guarding it against a colliding additional_pod_identity_configs entry.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
