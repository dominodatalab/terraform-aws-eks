# storage

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_efs_access_point.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.efs_backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.blobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_logging.buckets_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.buckets_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.block_public_accss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_request_payment_configuration.buckets_payer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_request_payment_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.buckets_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.buckets_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_elb_service_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.blobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | if set, use specified key for S3 buckets | `string` | `null` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | storage = {<br>      efs = {<br>        access\_point\_path = "Filesystem path for efs."<br>        backup\_vault = {<br>          create        = "Create backup vault for EFS toggle."<br>          force\_destroy = "Toggle to allow automatic destruction of all backups when destroying."<br>          backup = {<br>            schedule           = optional(string)<br>            cold\_storage\_after = "Move backup data to cold storage after this many days."<br>            delete\_after       = "Delete backup data after this many days."<br>          }<br>        }<br>      }<br>      s3 = {<br>        force\_destroy\_on\_deletion = "Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets"<br>      }<br>      ecr = {<br>        force\_destroy\_on\_deletion = "Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories"<br>      }<br>    }<br>  } | <pre>object({<br>    efs = optional(object({<br>      access_point_path = optional(string, "/domino")<br>      backup_vault = optional(object({<br>        create        = optional(bool, true)<br>        force_destroy = optional(bool, false)<br>        backup = optional(object({<br>          schedule           = optional(string, "0 12 * * ? *")<br>          cold_storage_after = optional(number, 35)<br>          delete_after       = optional(number, 125)<br>        }), {})<br>      }), {})<br>    }), {})<br>    s3 = optional(object({<br>      force_destroy_on_deletion = optional(bool, true)<br>    }), {})<br>    ecr = optional(object({<br>      force_destroy_on_deletion = optional(bool, true)<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of Subnets IDs to create EFS mount targets | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_registry"></a> [container\_registry](#output\_container\_registry) | ECR base registry URL |
| <a name="output_efs_access_point"></a> [efs\_access\_point](#output\_efs\_access\_point) | efs access point |
| <a name="output_efs_file_system"></a> [efs\_file\_system](#output\_efs\_file\_system) | efs file system |
| <a name="output_efs_security_group"></a> [efs\_security\_group](#output\_efs\_security\_group) | EFS security group id |
| <a name="output_iam_policies"></a> [iam\_policies](#output\_iam\_policies) | IAM Policy ARNs |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | S3 buckets name and arn |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
