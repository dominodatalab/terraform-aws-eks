output "infra" {
  description = "Infrastructure outputs."
  value       = module.infra
}

output "ssh_bastion_command" {
  description = "Command used in order to ssh to bastion."
  value       = var.bastion.enabled ? module.infra.bastion.ssh_bastion_command : null
}

output "domino_config_values" {
  description = "Values used to update the `domino.yml` for installation."
  value = {
    name = var.deploy_id
    autoscaler = {
      auto_discovery = {
        cluster_name = var.deploy_id
      }
      aws = {
        region = var.region
      }
    }
    internal_docker_registry = {
      s3_override = var.storage.s3.create ? {
        region         = var.region
        bucket         = module.infra.storage.s3.buckets.registry.bucket_name
        sse_kms_key_id = module.infra.kms.key_arn
      } : null
    }
    external_docker_registry = var.storage.ecr.create ? module.infra.storage.ecr.container_registry : null
    storage_classes = {
      block = {
        parameters = {
          kmsKeyId = module.infra.kms.key_arn
        }
      }
      shared = {
        efs = var.storage.filesystem_type != "none" ? {
          region          = var.region
          filesystem_id   = module.infra.storage.efs.file_system.id
          access_point_id = module.infra.storage.efs.access_point.id
        } : null
      }
      blob_storage = {
        projects = var.storage.s3.create ? {
          region         = var.region
          bucket         = module.infra.storage.s3.buckets.blobs.bucket_name
          sse_kms_key_id = module.infra.kms.key_arn
        } : null
        logs = var.storage.s3.create ? {
          region         = var.region
          bucket         = module.infra.storage.s3.buckets.logs.bucket_name
          sse_kms_key_id = module.infra.kms.key_arn

        } : null
        backups = var.storage.s3.create ? {
          region         = var.region
          bucket         = module.infra.storage.s3.buckets.backups.bucket_name
          sse_kms_key_id = module.infra.kms.key_arn
        } : null
        monitoring = {
          region = var.region
          bucket = module.infra.storage.s3.buckets.monitoring.bucket_name
        }
      }
    }
  }
}
