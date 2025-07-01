# storage

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.2 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_cloudformation_stack.fsx_ontap_scaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_datasync_location_efs.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_location_efs) | resource |
| [aws_datasync_location_fsx_ontap_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_location_fsx_ontap_file_system) | resource |
| [aws_datasync_task.efs_to_netapp_sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_task) | resource |
| [aws_datasync_task.netapp_to_efs_sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_task) | resource |
| [aws_ecr_pull_through_cache_rule.quay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_efs_access_point.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_fsx_ontap_file_system.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_file_system) | resource |
| [aws_fsx_ontap_storage_virtual_machine.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_storage_virtual_machine) | resource |
| [aws_fsx_ontap_volume.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_volume) | resource |
| [aws_iam_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.efs_backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.efs_backup_role_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.blobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.costs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_logging.buckets_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.buckets_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.block_public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_request_payment_configuration.buckets_payer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_request_payment_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.buckets_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.buckets_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_secretsmanager_secret.netapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.netapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.datasync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.netapp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.datasync_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.datasync_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.netapp_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_password.netapp](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.check_backup_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.pull_through_cache_deletion](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.secrets_cleanup](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.set_monitoring_private_acl](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.wait_for_secrets](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_elb_service_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy.aws_backup_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.blobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.costs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr_pull_through_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_secretsmanager_secret_version.netapp_creds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_subnet.ds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br/>    key\_arn = KMS key arn.<br/>    enabled = KMS key is enabled | <pre>object({<br/>    key_id  = string<br/>    key_arn = string<br/>    enabled = bool<br/>  })</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | id = VPC ID.<br/>    subnets = {<br/>      public = List of public Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      private = List of private Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet id<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      pod = List of pod Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>    } | <pre>object({<br/>    vpc_id = string<br/>    subnets = object({<br/>      public = optional(list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      })), [])<br/>      private = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      pod = optional(list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      })), [])<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_storage"></a> [storage](#input\_storage) | storage = {<br/>      filesystem\_type = File system type(netapp\|efs\|none)<br/>      efs = {<br/>        access\_point\_path = Filesystem path for efs.<br/>        backup\_vault = {<br/>          create        = Create backup vault for EFS toggle.<br/>          force\_destroy = Toggle to allow automatic destruction of all backups when destroying.<br/>          backup = {<br/>            schedule           = Cron-style schedule for EFS backup vault (default: once a day at 12pm).<br/>            cold\_storage\_after = Move backup data to cold storage after this many days.<br/>            delete\_after       = Delete backup data after this many days.<br/>          }<br/>        }<br/>      }<br/>      netapp = {<br/>        migrate\_from\_efs = {<br/>          enabled =  When enabled, both EFS and NetApp resources will be provisioned simultaneously during the migration period.<br/>          datasync = {<br/>            enabled  = Toggle to enable AWS DataSync for automated data transfer from EFS to NetApp FSx.<br/>            schedule = Cron-style schedule for the DataSync task, specifying how often the data transfer will occur (default: hourly).<br/>            verify\_mode = One of: POINT\_IN\_TIME\_CONSISTENT, ONLY\_FILES\_TRANSFERRED, NONE.<br/>          }<br/>        }<br/>        deployment\_type = netapp ontap deployment type,('MULTI\_AZ\_1', 'MULTI\_AZ\_2', 'SINGLE\_AZ\_1', 'SINGLE\_AZ\_2')<br/>        storage\_capacity = Filesystem Storage capacity<br/>        throughput\_capacity = Filesystem throughput capacity<br/>        automatic\_backup\_retention\_days = How many days to keep backups<br/>        daily\_automatic\_backup\_start\_time = Start time in 'HH:MM' format to initiate backups<br/><br/>        storage\_capacity\_autosizing = Options for the FXN automatic storage capacity increase, cloudformation template<br/>          enabled                     = Enable automatic storage capacity increase.<br/>          threshold                  = Used storage capacity threshold.<br/>          percent\_capacity\_increase  = The percentage increase in storage capacity when used storage exceeds<br/>                                       LowFreeDataStorageCapacityThreshold. Minimum increase is 10 %.<br/>          notification\_email\_address = The email address for alarm notification.<br/>        }<br/>        volume = {<br/>          create                     = Create a volume associated with the filesystem.<br/>          name\_suffix                = The suffix to name the volume<br/>          storage\_efficiency\_enabled = Toggle storage\_efficiency\_enabled<br/>          junction\_path              = filesystem junction path<br/>          size\_in\_megabytes          = The size of the volume<br/>      }<br/>      s3 = {<br/>        force\_destroy\_on\_deletion = Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets.<br/>      }<br/>      ecr = {<br/>        force\_destroy\_on\_deletion = Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories.<br/>      }<br/>      enable\_remote\_backup = Enable tagging required for cross-account backups<br/>      costs\_enabled = Determines whether to provision domino cost related infrastructures, ie, long term storage<br/>    }<br/>  } | <pre>object({<br/>    filesystem_type = string<br/>    efs = optional(object({<br/>      access_point_path = optional(string)<br/>      backup_vault = optional(object({<br/>        create        = optional(bool)<br/>        force_destroy = optional(bool)<br/>        backup = optional(object({<br/>          schedule           = optional(string)<br/>          cold_storage_after = optional(number)<br/>          delete_after       = optional(number)<br/>        }))<br/>      }))<br/>    }))<br/>    netapp = optional(object({<br/>      migrate_from_efs = optional(object({<br/>        enabled = optional(bool)<br/>        datasync = optional(object({<br/>          enabled     = optional(bool)<br/>          target      = optional(string)<br/>          schedule    = optional(string)<br/>          verify_mode = optional(string)<br/>        }))<br/>      }))<br/>      deployment_type                   = optional(string)<br/>      storage_capacity                  = optional(number)<br/>      throughput_capacity               = optional(number)<br/>      automatic_backup_retention_days   = optional(number)<br/>      daily_automatic_backup_start_time = optional(string)<br/>      storage_capacity_autosizing = optional(object({<br/>        enabled                    = optional(bool)<br/>        threshold                  = optional(number)<br/>        percent_capacity_increase  = optional(number)<br/>        notification_email_address = optional(string)<br/>      }))<br/>      volume = optional(object({<br/>        name_suffix                = optional(string)<br/>        storage_efficiency_enabled = optional(bool)<br/>        create                     = optional(bool)<br/>        junction_path              = optional(string)<br/>        size_in_megabytes          = optional(number)<br/>      }))<br/>    }))<br/>    s3 = optional(object({<br/>      create                    = optional(bool)<br/>      force_destroy_on_deletion = optional(bool)<br/>    }))<br/>    ecr = optional(object({<br/>      create                    = optional(bool)<br/>      force_destroy_on_deletion = optional(bool)<br/>    }))<br/>    enable_remote_backup = optional(bool)<br/>    costs_enabled        = optional(bool)<br/>  })</pre> | n/a | yes |
| <a name="input_use_fips_endpoint"></a> [use\_fips\_endpoint](#input\_use\_fips\_endpoint) | Use aws FIPS endpoints | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | efs = {<br/>      access\_point      = EFS access point.<br/>      file\_system       = EFS file\_system.<br/>      security\_group\_id = EFS security group id.<br/>    }<br/>    s3 = {<br/>      buckets        = "S3 buckets name and arn"<br/>      iam\_policy\_arn = S3 IAM Policy ARN.<br/>    }<br/>    ecr = {<br/>      container\_registry = ECR base registry URL. Grab the base AWS account ECR URL and add the deploy\_id. Domino will append /environment and /model.<br/>      iam\_policy\_arn     = ECR IAM Policy ARN.<br/>      calico\_image\_registry = Image registry for Calico. Will be a pull through cache for Quay.io unless in GovCloud, China, or have FIPS enabled.<br/>    } |
<!-- END_TF_DOCS -->
