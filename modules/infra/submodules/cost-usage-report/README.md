# cost-usage-report

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cur_network"></a> [cur\_network](#module\_cur\_network) | ./../network | n/a |

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
| [aws_iam_role.aws_cur_crawler_component_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.aws_cur_lambda_executor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cur_lambda_initializer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.aws_cur_crawler_component_function_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_cur_lambda_executor_rpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cur_lambda_initializer_rp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_code_signing_config.lambda_csc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_code_signing_config) | resource |
| [aws_lambda_function.aws_s3_cur_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.cur_lambda_initializer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.aws_s3_cur_event_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
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
| [archive_file.aws_s3_cur_notification_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.cur_initializer_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.athena_result](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_cur_crawler_component_function_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_cur_lambda_executor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_cur_lambda_executor_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_crawler_component_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_lambda_initializer_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_lambda_initializer_pd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_key_global](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami                   = optional(string, null)<br>    bootstrap_extra_args  = optional(string, "")<br>    instance_types        = list(string)<br>    spot                  = optional(bool, false)<br>    min_per_az            = number<br>    max_per_az            = number<br>    desired_per_az        = number<br>    availability_zone_ids = list(string)<br>    labels                = map(string)<br>    taints = optional(list(object({<br>      key    = string<br>      value  = optional(string)<br>      effect = string<br>    })), [])<br>    tags = optional(map(string), {})<br>    gpu  = optional(bool, null)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_athena_cur_result_bucket_suffix"></a> [athena\_cur\_result\_bucket\_suffix](#input\_athena\_cur\_result\_bucket\_suffix) | Name of the S3 bucket into which CUR will put the cost data. | `string` | `"aws-athena-query-results-costs"` | no |
| <a name="input_aws_glue_database_suffix"></a> [aws\_glue\_database\_suffix](#input\_aws\_glue\_database\_suffix) | Name of the Cost and Usage Report which will be created. | `string` | `"athena-cur-cost-db"` | no |
| <a name="input_cur_report_bucket_name_suffix"></a> [cur\_report\_bucket\_name\_suffix](#input\_cur\_report\_bucket\_name\_suffix) | Name of the S3 bucket into which CUR will put the cost data. | `string` | `"cur-report"` | no |
| <a name="input_cur_report_name"></a> [cur\_report\_name](#input\_cur\_report\_name) | Name of the Cost and Usage Report which will be created. | `string` | `"cur-report"` | no |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | <pre>object(<br>    {<br>      compute = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      platform = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 1)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 1)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "platform"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 100)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 100<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      gpu = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["g4dn.xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default-gpu"<br>            "nvidia.com/gpu"              = true<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>            })), [{<br>            key    = "nvidia.com/gpu"<br>            value  = "true"<br>            effect = "NO_SCHEDULE"<br>            }<br>          ])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      })<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_flow_log_bucket_arn"></a> [flow\_log\_bucket\_arn](#input\_flow\_log\_bucket\_arn) | Bucket for vpc flow logging | `object({ arn = string })` | `null` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | enabled             = "Toggle, if set use either the specified KMS key\_id or a Domino-generated one"<br>    key\_id              = optional(string, null)<br>    additional\_policies = "Allows setting additional KMS key policies when using a Domino-generated key" | <pre>object({<br>    enabled             = optional(bool, true)<br>    key_id              = optional(string, null)<br>    additional_policies = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | vpc = {<br>      id = Existing vpc id, it will bypass creation by this module.<br>      subnets = {<br>        private = Existing private subnets.<br>        public  = Existing public subnets.<br>        pod     = Existing pod subnets.<br>      }), {})<br>    }), {})<br>    network\_bits = {<br>      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.<br>      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>    }<br>    cidrs = {<br>      vpc     = The IPv4 CIDR block for the VPC.<br>      pod     = The IPv4 CIDR block for the Pod subnets.<br>    }<br>    use\_pod\_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking. | <pre>object({<br>    vpc = optional(object({<br>      id = optional(string, null)<br>      subnets = optional(object({<br>        private = optional(list(string), [])<br>        public  = optional(list(string), [])<br>        pod     = optional(list(string), [])<br>      }), {})<br>    }), {})<br>    network_bits = optional(object({<br>      public  = optional(number, 27)<br>      private = optional(number, 19)<br>      pod     = optional(number, 19)<br>      }<br>    ), {})<br>    cidrs = optional(object({<br>      vpc = optional(string, "10.0.0.0/16")<br>      pod = optional(string, "100.64.0.0/16")<br>    }), {})<br>    use_pod_cidr = optional(bool, true)<br>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_report_compression"></a> [report\_compression](#input\_report\_compression) | Compression format for report. Valid values are: GZIP, ZIP, Parquet. If Parquet is used, then format must also be Parquet. | `string` | `"Parquet"` | no |
| <a name="input_report_format"></a> [report\_format](#input\_report\_format) | Format for report. Valid values are: textORcsv, Parquet. If Parquet is used, then Compression must also be Parquet. | `string` | `"Parquet"` | no |
| <a name="input_report_frequency"></a> [report\_frequency](#input\_report\_frequency) | How often the Cost and Usage Report will be generated. HOURLY or DAILY. | `string` | `"DAILY"` | no |
| <a name="input_report_versioning"></a> [report\_versioning](#input\_report\_versioning) | Whether reports should be overwritten or new ones should be created. | `string` | `"OVERWRITE_REPORT"` | no |
| <a name="input_s3_bucket_prefix"></a> [s3\_bucket\_prefix](#input\_s3\_bucket\_prefix) | Prefix in the S3 bucket to put reports. | `string` | `"cur"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags which will be applied to provisioned resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | athena\_info\_configs = "Athena based cost reporting config information for kubecost cost-analyzer"<br>   athena\_region"  = "athena region"<br>   athena\_query\_result\_s3 = "S3 location for athena query results"<br>   cur\_report\_bucket\_name = "Name of S3 bucket used for storing CUR data. This may be provisioned by this module or not."<br>   glue\_catalog\_database\_name = "Name of the Glue Catalog Database which is populated with CUR data."<br>   glue\_catalog\_table\_name = "Name of the Glue Catalog table which is populated with CUR data."<br>   s3\_bucket\_region  = "Region where the S3 bucket used for storing CUR data is provisioned. This may be provisioned by this module or not."<br>   report\_name = "Name of the provisioned Cost and Usage Report." |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
