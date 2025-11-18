# cost-usage-report

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_athena_workgroup.athena_work_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_cur_report_definition.aws_cur_report_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cur_report_definition) | resource |
| [aws_glue_catalog_database.aws_cur_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_catalog_table.aws_cur_report_status_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_glue_crawler.aws_cur_crawler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_crawler) | resource |
| [aws_glue_security_configuration.lambda_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_security_configuration) | resource |
| [aws_iam_policy.aws_cur_lambda_executor_p](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cur_lambda_initializer_p](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.query_cost_usage_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_cur_crawler_component_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.aws_cur_lambda_executor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cur_lambda_initializer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.aws_cur_crawler_component_function_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_cur_lambda_executor_rpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cur_crawler_glue_service_role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cur_lambda_initializer_rp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_code_signing_config.lambda_csc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_code_signing_config) | resource |
| [aws_lambda_function.aws_s3_cur_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.cur_lambda_initializer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.aws_s3_cur_event_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_notification.aws_put_s3_cur_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.buckets_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_signer_signing_profile.signing_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/signer_signing_profile) | resource |
| [aws_signer_signing_profile_permission.sp_permission_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/signer_signing_profile_permission) | resource |
| [aws_signer_signing_profile_permission.sp_permission_start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/signer_signing_profile_permission) | resource |
| [aws_sqs_queue.lambda_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_vpc_endpoint.aws_glue_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_policy.aws_cur_crawler_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_policy) | resource |
| [archive_file.aws_s3_cur_notification_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.cur_initializer_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.aws_glue_service_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_cur_crawler_component_function_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_cur_lambda_executor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_cur_lambda_executor_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_crawler_component_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_lambda_initializer_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_lambda_initializer_pd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.query_cost_usage_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cost_usage_report"></a> [cost\_usage\_report](#input\_cost\_usage\_report) | athena\_result\_bucket\_suffix = Name of the S3 bucket into which Athena will put the cost data.<br/>    report\_bucket\_name\_suffix = Suffix of the S3 bucket into which CUR will put the cost data.<br/>    aws\_glue\_database\_suffix = Suffix of the Glue's DB.<br/>    report\_name = Name of the Cost and Usage Report which will be created.<br/>    report\_frequency = How often the Cost and Usage Report will be generated. HOURLY or DAILY.<br/>    report\_versioning = Whether reports should be overwritten or new ones should be created.<br/>    report\_format = Format for report. Valid values are: textORcsv, Parquet. If Parquet is used, then Compression must also be Parquet.<br/>    report\_compression = Compression format for report. Valid values are: GZIP, ZIP, Parquet. If Parquet is used, then format must also be Parquet.<br/>    s3\_bucket\_prefix = Prefix in the S3 bucket to put reports. | <pre>object({<br/>    athena_result_bucket_suffix = string<br/>    report_bucket_name_suffix   = string<br/>    aws_glue_database_suffix    = string<br/>    report_name                 = string<br/>    report_frequency            = string<br/>    report_versioning           = string<br/>    report_format               = string<br/>    report_compression          = string<br/>    s3_bucket_prefix            = string<br/>  })</pre> | <pre>{<br/>  "athena_result_bucket_suffix": "aws-athena-query-results-costs",<br/>  "aws_glue_database_suffix": "athena-cur-cost-db",<br/>  "report_bucket_name_suffix": "cur-report",<br/>  "report_compression": "Parquet",<br/>  "report_format": "Parquet",<br/>  "report_frequency": "DAILY",<br/>  "report_name": "cur-report",<br/>  "report_versioning": "OVERWRITE_REPORT",<br/>  "s3_bucket_prefix": "cur"<br/>}</pre> | no |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_kms_info"></a> [kms\_info](#input\_kms\_info) | key\_id  = KMS key id.<br/>    key\_arn = KMS key arn.<br/>    enabled = KMS key is enabled | <pre>object({<br/>    key_id  = string<br/>    key_arn = string<br/>    enabled = bool<br/>  })</pre> | n/a | yes |
| <a name="input_network_info"></a> [network\_info](#input\_network\_info) | vpc\_id = VPC ID.<br/>    subnets = {<br/>      public = List of public Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      private = List of private Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>      pod = List of pod Subnets.<br/>      [{<br/>        name = Subnet name.<br/>        subnet\_id = Subnet ud<br/>        az = Subnet availability\_zone<br/>        az\_id = Subnet availability\_zone\_id<br/>      }]<br/>    } | <pre>object({<br/>    vpc_id = string<br/>    subnets = object({<br/>      public = list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      }))<br/>      private = optional(list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      })), [])<br/>      pod = optional(list(object({<br/>        name      = string<br/>        subnet_id = string<br/>        az        = string<br/>        az_id     = string<br/>      })), [])<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags which will be applied to provisioned resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | athena\_info\_configs = "Athena based cost reporting config information for kubecost cost-analyzer"<br/>   athena\_region"  = "athena region"<br/>   athena\_query\_result\_s3 = "S3 location for athena query results"<br/>   cur\_report\_bucket\_name = "Name of S3 bucket used for storing CUR data. This may be provisioned by this module or not."<br/>   glue\_catalog\_database\_name = "Name of the Glue Catalog Database which is populated with CUR data."<br/>   glue\_catalog\_table\_name = "Name of the Glue Catalog table which is populated with CUR data."<br/>   glue\_catalog\_status\_table\_name = "Name of the Glue Catalog table which is populated with CUR data's status."<br/>   report\_name = "Name of the provisioned Cost and Usage Report."<br/>   s3\_bucket\_region  = "Region where the S3 bucket used for storing CUR data is provisioned. This may be provisioned by this module or not."<br/>   athena\_work\_group = "Athena workgroup to execute queries"<br/>   cur\_iam\_policy\_arn = CUR IAM Policy ARN. |
<!-- END_TF_DOCS -->
