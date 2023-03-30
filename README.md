# terraform-aws-eks

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/dominodatalab/terraform-aws-eks/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/dominodatalab/terraform-aws-eks/tree/main)

## Create SSH Key pair
### Prerequisites
* Host with `ssh-keygen` installed
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform) >= v1.3.0
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) cli >= 1.24.0


### Command
```bash
 ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem && chmod 400 domino.pem
```

## Create terraform remote state bucket(OPTIONAL)
* Authenticate with aws, make sure that environment variables: `AWS_REGION`, `AWS_ACCESS_KEY_ID` ,`AWS_SECRET_ACCESS_KEY` are set. If your account has MFA set up you will also need `AWS_SESSION_TOKEN`.

#### 1. Create Bucket(if you already have a bucket just set the `AWS_TERRAFORM_REMOTE_STATE_BUCKET` to its name, and skip this step):
```bash
export AWS_ACCOUNT="$(aws sts get-caller-identity | jq -r .Account)"
export AWS_TERRAFORM_REMOTE_STATE_BUCKET="domino-terraform-rs-${AWS_ACCOUNT}-${AWS_REGION}"

aws s3api create-bucket \
    --bucket "${AWS_TERRAFORM_REMOTE_STATE_BUCKET}" \
    --region ${AWS_REGION} \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}" | jq .
```

#### Verify bucket exists

```bash
aws s3api head-bucket --bucket "${AWS_TERRAFORM_REMOTE_STATE_BUCKET}"
```
You should NOT see an error.

## 2. Initialize the terraform remote-state
Create a file called terraform.tf(the name does not matter) with the following content
```hcl
terraform {
  backend "s3" {}
}
```

```bash
### Set the deploy id. This will be used later as well.
export TF_VAR_deploy_id="domino-eks-1"  ## <-- Feel free to rename.
terraform init -migrate-state \
    -backend-config="bucket=${AWS_TERRAFORM_REMOTE_STATE_BUCKET}" \
    -backend-config="key=domino-eks/${TF_VAR_deploy_id}" \
    -backend-config="region=${AWS_REGION}"
```



## If you need to delete the bucket

```bash

aws s3 rb s3://"${AWS_TERRAFORM_REMOTE_STATE_BUCKET}" --force
```

# Terraform-docs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./submodules/bastion | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./submodules/eks | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./submodules/network | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ./submodules/storage | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_kms_alias.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_ec2_instance_type.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_iam_policy_document.kms_key_global](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [tls_public_key.domino](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/public_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami                   = optional(string, null)<br>    bootstrap_extra_args  = optional(string, "")<br>    instance_types        = list(string)<br>    spot                  = optional(bool, false)<br>    min_per_az            = number<br>    max_per_az            = number<br>    desired_per_az        = number<br>    availability_zone_ids = list(string)<br>    labels                = map(string)<br>    taints = optional(list(object({<br>      key    = string<br>      value  = optional(string)<br>      effect = string<br>    })), [])<br>    tags = optional(map(string), {})<br>    gpu  = optional(bool, null)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_bastion"></a> [bastion](#input\_bastion) | ami                      = Ami id. Defaults to latest 'amazon\_linux\_2' ami.<br>    instance\_type            = Instance type.<br>    authorized\_ssh\_ip\_ranges = List of CIDR ranges permitted for the bastion ssh access.<br>    username                 = Bastion user.<br>    install\_binaries         = Toggle to install required Domino binaries in the bastion. | <pre>object({<br>    enabled                  = optional(bool, true)<br>    ami_id                   = optional(string, null) # default will use the latest 'amazon_linux_2' ami<br>    instance_type            = optional(string, "t2.micro")<br>    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])<br>    username                 = optional(string, "ec2-user")<br>    install_binaries         = optional(bool, false)<br>  })</pre> | `null` | no |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | <pre>object(<br>    {<br>      compute = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      platform = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 1)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 1)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "platform"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 100)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 100<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      gpu = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["g4dn.xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default-gpu"<br>            "nvidia.com/gpu"              = true<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>            })), [{<br>            key    = "nvidia.com/gpu"<br>            value  = "true"<br>            effect = "NO_SCHEDULE"<br>            }<br>          ])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      })<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | `"domino-eks"` | no |
| <a name="input_eks"></a> [eks](#input\_eks) | k8s\_version = "EKS cluster k8s version."<br>    kubeconfig = {<br>      extra\_args = "Optional extra args when generating kubeconfig."<br>      path       = "Fully qualified path name to write the kubeconfig file."<br>    }<br>    public\_access = {<br>      enabled = "Enable EKS API public endpoint."<br>      cidrs   = "List of CIDR ranges permitted for accessing the EKS public endpoint."<br>    }<br>    "Custom role maps for aws auth configmap"<br>    custom\_role\_maps = {<br>      rolearn = string<br>      username = string<br>      groups = list(string)<br>    }<br>    master\_role\_names = "IAM role names to be added as masters in eks."<br>    cluster\_addons = "EKS cluster addons. vpc-cni is installed separately."<br>    ssm\_log\_group\_name = "CloudWatch log group to send the SSM session logs to."<br>  } | <pre>object({<br>    k8s_version = optional(string, "1.25")<br>    kubeconfig = optional(object({<br>      extra_args = optional(string, "")<br>      path       = optional(string)<br>    }), {})<br>    public_access = optional(object({<br>      enabled = optional(bool, false)<br>      cidrs   = optional(list(string), [])<br>    }), {})<br>    custom_role_maps = optional(list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    })), [])<br>    master_role_names  = optional(list(string), [])<br>    cluster_addons     = optional(list(string), [])<br>    ssm_log_group_name = optional(string, "session-manager")<br>  })</pre> | `{}` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | enabled = "Toggle,if set use either the specified KMS key\_id or a Domino-generated one"<br>    key\_id  = optional(string, null) | <pre>object({<br>    enabled = optional(bool, true)<br>    key_id  = optional(string, null)<br>  })</pre> | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | vpc = {<br>      id = Existing vpc id, it will bypass creation by this module.<br>      subnets = {<br>        private = Existing private subnets.<br>        public  = Existing public subnets.<br>        pod     = Existing pod subnets.<br>      }), {})<br>    }), {})<br>    network\_bits = {<br>      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.<br>      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>    }<br>    cidrs = {<br>      vpc     = The IPv4 CIDR block for the VPC.<br>      pod     = The IPv4 CIDR block for the Pod subnets.<br>    }<br>    use\_pod\_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking. | <pre>object({<br>    vpc = optional(object({<br>      id = optional(string, null)<br>      subnets = optional(object({<br>        private = optional(list(string), [])<br>        public  = optional(list(string), [])<br>        pod     = optional(list(string), [])<br>      }), {})<br>    }), {})<br>    network_bits = optional(object({<br>      public  = optional(number, 27)<br>      private = optional(number, 19)<br>      pod     = optional(number, 19)<br>      }<br>    ), {})<br>    cidrs = optional(object({<br>      vpc = optional(string, "10.0.0.0/16")<br>      pod = optional(string, "100.64.0.0/16")<br>    }), {})<br>    use_pod_cidr = optional(bool, true)<br>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Optional hosted zone for External DNSone. | `string` | `null` | no |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |
| <a name="input_storage"></a> [storage](#input\_storage) | storage = {<br>      efs = {<br>        access\_point\_path = Filesystem path for efs.<br>        backup\_vault = {<br>          create        = Create backup vault for EFS toggle.<br>          force\_destroy = Toggle to allow automatic destruction of all backups when destroying.<br>          backup = {<br>            schedule           = Cron-style schedule for EFS backup vault (default: once a day at 12pm).<br>            cold\_storage\_after = Move backup data to cold storage after this many days.<br>            delete\_after       = Delete backup data after this many days.<br>          }<br>        }<br>      }<br>      s3 = {<br>        force\_destroy\_on\_deletion = Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets.<br>      }<br>      ecr = {<br>        force\_destroy\_on\_deletion = Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories.<br>      }<br>    }<br>  } | <pre>object({<br>    efs = optional(object({<br>      access_point_path = optional(string, "/domino")<br>      backup_vault = optional(object({<br>        create        = optional(bool, true)<br>        force_destroy = optional(bool, false)<br>        backup = optional(object({<br>          schedule           = optional(string, "0 12 * * ? *")<br>          cold_storage_after = optional(number, 35)<br>          delete_after       = optional(number, 125)<br>        }), {})<br>      }), {})<br>    }), {})<br>    s3 = optional(object({<br>      force_destroy_on_deletion = optional(bool, true)<br>    }), {})<br>    ecr = optional(object({<br>      force_destroy_on_deletion = optional(bool, true)<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion"></a> [bastion](#output\_bastion) | Bastion details, if it was created. |
| <a name="output_domino_key_pair"></a> [domino\_key\_pair](#output\_domino\_key\_pair) | Domino key pair |
| <a name="output_eks"></a> [eks](#output\_eks) | EKS details. |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | Domino instance URL. |
| <a name="output_kms"></a> [kms](#output\_kms) | KMS key details, if enabled. |
| <a name="output_network"></a> [network](#output\_network) | Network details. |
| <a name="output_storage"></a> [storage](#output\_storage) | Storage details. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.33.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./submodules/bastion | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./submodules/eks | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./submodules/network | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ./submodules/storage | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_kms_alias.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_ec2_instance_type.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_iam_policy_document.kms_key_global](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [tls_public_key.domino](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/public_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami                   = optional(string, null)<br>    bootstrap_extra_args  = optional(string, "")<br>    instance_types        = list(string)<br>    spot                  = optional(bool, false)<br>    min_per_az            = number<br>    max_per_az            = number<br>    desired_per_az        = number<br>    availability_zone_ids = list(string)<br>    labels                = map(string)<br>    taints = optional(list(object({<br>      key    = string<br>      value  = optional(string)<br>      effect = string<br>    })), [])<br>    tags = optional(map(string), {})<br>    gpu  = optional(bool, null)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_bastion"></a> [bastion](#input\_bastion) | ami                      = Ami id. Defaults to latest 'amazon\_linux\_2' ami.<br>    instance\_type            = Instance type.<br>    authorized\_ssh\_ip\_ranges = List of CIDR ranges permitted for the bastion ssh access.<br>    username                 = Bastion user.<br>    install\_binaries         = Toggle to install required Domino binaries in the bastion. | <pre>object({<br>    ami_id                   = optional(string, null) # default will use the latest 'amazon_linux_2' ami<br>    instance_type            = optional(string, "t2.micro")<br>    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])<br>    username                 = optional(string, "ec2-user")<br>    install_binaries         = optional(bool, false)<br>  })</pre> | `null` | no |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | <pre>object(<br>    {<br>      compute = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      platform = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["m5.2xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 1)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 1)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "platform"<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })), [])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 100)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 100<br>            type = "gp3"<br>            }<br>          )<br>      }),<br>      gpu = object(<br>        {<br>          ami                   = optional(string, null)<br>          bootstrap_extra_args  = optional(string, "")<br>          instance_types        = optional(list(string), ["g4dn.xlarge"])<br>          spot                  = optional(bool, false)<br>          min_per_az            = optional(number, 0)<br>          max_per_az            = optional(number, 10)<br>          desired_per_az        = optional(number, 0)<br>          availability_zone_ids = list(string)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default-gpu"<br>            "nvidia.com/gpu"              = true<br>          })<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>            })), [{<br>            key    = "nvidia.com/gpu"<br>            value  = "true"<br>            effect = "NO_SCHEDULE"<br>            }<br>          ])<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number, 1000)<br>            type = optional(string, "gp3")<br>            }), {<br>            size = 1000<br>            type = "gp3"<br>            }<br>          )<br>      })<br>  })</pre> | n/a | yes |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | `"domino-eks"` | no |
| <a name="input_eks"></a> [eks](#input\_eks) | k8s\_version = "EKS cluster k8s version."<br>    kubeconfig = {<br>      extra\_args = "Optional extra args when generating kubeconfig."<br>      path       = "Fully qualified path name to write the kubeconfig file."<br>    }<br>    public\_access = {<br>      enabled = "Enable EKS API public endpoint."<br>      cidrs   = "List of CIDR ranges permitted for accessing the EKS public endpoint."<br>    }<br>    "Custom role maps for aws auth configmap"<br>    custom\_role\_maps = {<br>      rolearn = string<br>      username = string<br>      groups = list(string)<br>    }<br>    master\_role\_names = "IAM role names to be added as masters in eks."<br>    cluster\_addons = "EKS cluster addons. vpc-cni is installed separately." | <pre>object({<br>    k8s_version = optional(string, "1.25")<br>    kubeconfig = optional(object({<br>      extra_args = optional(string, "")<br>      path       = optional(string)<br>    }), {})<br>    public_access = optional(object({<br>      enabled = optional(bool, false)<br>      cidrs   = optional(list(string), [])<br>    }), {})<br>    custom_role_maps = optional(list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    })), [])<br>    master_role_names = optional(list(string), [])<br>    cluster_addons    = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | enabled = "Toggle,if set use either the specified KMS key\_id or a Domino-generated one"<br>    key\_id  = optional(string, null) | <pre>object({<br>    enabled = optional(bool, false)<br>    key_id  = optional(string, null)<br>  })</pre> | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | vpc = {<br>      id = Existing vpc id, it will bypass creation by this module.<br>      subnets = {<br>        private = Existing private subnets.<br>        public  = Existing public subnets.<br>        pod     = Existing pod subnets.<br>      }), {})<br>    }), {})<br>    network\_bits = {<br>      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.<br>      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>    }<br>    cidrs = {<br>      vpc     = The IPv4 CIDR block for the VPC.<br>      pod     = The IPv4 CIDR block for the Pod subnets.<br>    }<br>    use\_pod\_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking. | <pre>object({<br>    vpc = optional(object({<br>      id = optional(string, null)<br>      subnets = optional(object({<br>        private = optional(list(string), [])<br>        public  = optional(list(string), [])<br>        pod     = optional(list(string), [])<br>      }), {})<br>    }), {})<br>    network_bits = optional(object({<br>      public  = optional(number, 27)<br>      private = optional(number, 19)<br>      pod     = optional(number, 19)<br>      }<br>    ), {})<br>    cidrs = optional(object({<br>      vpc = optional(string, "10.0.0.0/16")<br>      pod = optional(string, "100.64.0.0/16")<br>    }), {})<br>    use_pod_cidr = optional(bool, true)<br>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Optional hosted zone for External DNSone. | `string` | `null` | no |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |
| <a name="input_storage"></a> [storage](#input\_storage) | storage = {<br>      efs = {<br>        access\_point\_path = Filesystem path for efs.<br>        backup\_vault = {<br>          create        = Create backup vault for EFS toggle.<br>          force\_destroy = Toggle to allow automatic destruction of all backups when destroying.<br>          backup = {<br>            schedule           = Cron-style schedule for EFS backup vault (default: once a day at 12pm).<br>            cold\_storage\_after = Move backup data to cold storage after this many days.<br>            delete\_after       = Delete backup data after this many days.<br>          }<br>        }<br>      }<br>      s3 = {<br>        force\_destroy\_on\_deletion = Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets.<br>      }<br>      ecr = {<br>        force\_destroy\_on\_deletion = Toogle to allow recursive deletion of all objects in the ECR repositories. if 'false' terraform will NOT be able to delete non-empty repositories.<br>      }<br>    }<br>  } | <pre>object({<br>    efs = optional(object({<br>      access_point_path = optional(string, "/domino")<br>      backup_vault = optional(object({<br>        create        = optional(bool, true)<br>        force_destroy = optional(bool, false)<br>        backup = optional(object({<br>          schedule           = optional(string, "0 12 * * ? *")<br>          cold_storage_after = optional(number, 35)<br>          delete_after       = optional(number, 125)<br>        }), {})<br>      }), {})<br>    }), {})<br>    s3 = optional(object({<br>      force_destroy_on_deletion = optional(bool, true)<br>    }), {})<br>    ecr = optional(object({<br>      force_destroy_on_deletion = optional(bool, true)<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion"></a> [bastion](#output\_bastion) | Bastion details, if it was created. |
| <a name="output_domino_key_pair"></a> [domino\_key\_pair](#output\_domino\_key\_pair) | Domino key pair |
| <a name="output_eks"></a> [eks](#output\_eks) | EKS details. |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | Domino instance URL. |
| <a name="output_kms"></a> [kms](#output\_kms) | KMS key details, if enabled. |
| <a name="output_network"></a> [network](#output\_network) | Network details. |
| <a name="output_storage"></a> [storage](#output\_storage) | Storage details. |
<!-- END_TF_DOCS -->
