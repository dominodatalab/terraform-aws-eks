# terraform-aws-eks

## Create SSH Key pair
### Prerequisites
* Host with `ssh-keygen` installed

### Command
```bash
 ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem
```

## Create terraform remote state bucket(OPTIONAL)
* Authenticate with aws, make sure that environment variables: `AWS_REGION`, `AWS_ACCESS_KEY_ID` ,`AWS_SECRET_ACCESS_KEY` are set. If your account has MFA set up you will also need `AWS_SESSION_TOKEN`.

### Prerequisites
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* jq (Optional, it parses the api response)

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
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.32.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./submodules/bastion | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./submodules/eks | n/a |
| <a name="module_k8s_setup"></a> [k8s\_setup](#module\_k8s\_setup) | ./submodules/k8s | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./submodules/network | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ./submodules/storage | n/a |
| <a name="module_subnets_cidr"></a> [subnets\_cidr](#module\_subnets\_cidr) | ./submodules/subnets-cidr | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.domino](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ec2_instance_type_offerings.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type_offerings) | data source |
| [aws_iam_policy_document.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.eks_master_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [null_data_source.validate_zones](https://registry.terraform.io/providers/hashicorp/null/latest/docs/data-sources/data_source) | data source |
| [tls_public_key.domino](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/public_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami            = optional(string)<br>    instance_type  = string<br>    min_per_az     = number<br>    max_per_az     = number<br>    desired_per_az = number<br>    labels         = map(string)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `{}` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Availibility zones to distribute the deployment, EKS needs at least 2,https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html.<br>    Note that setting this variable bypasses validation of the status of the zones data 'aws\_availability\_zones' 'available'.<br>    Caller is responsible for validating status of these zones. | `list(string)` | `[]` | no |
| <a name="input_base_cidr_block"></a> [base\_cidr\_block](#input\_base\_cidr\_block) | CIDR block to serve the main private and public subnets. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_bastion_ami_id"></a> [bastion\_ami\_id](#input\_bastion\_ami\_id) | AMI ID for the bastion EC2 instance, otherwise we will use the latest 'amazon\_linux\_2' ami | `string` | `""` | no |
| <a name="input_create_bastion"></a> [create\_bastion](#input\_create\_bastion) | Create bastion toggle. | `bool` | `false` | no |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | <pre>object(<br>    {<br>      compute = object(<br>        {<br>          ami            = optional(string)<br>          instance_type  = optional(string, "m5.2xlarge")<br>          min_per_az     = optional(number, 0)<br>          max_per_az     = optional(number, 10)<br>          desired_per_az = optional(number, 1)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default"<br>          })<br>          volume = optional(object(<br>            {<br>              size = optional(number, 100)<br>              type = optional(string, "gp3")<br>            }),<br>            {<br>              size = 100<br>              type = "gp3"<br>            }<br>          )<br>      }),<br>      platform = object(<br>        {<br>          ami            = optional(string)<br>          instance_type  = optional(string, "m5.4xlarge")<br>          min_per_az     = optional(number, 0)<br>          max_per_az     = optional(number, 10)<br>          desired_per_az = optional(number, 1)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "platform"<br>          })<br>          volume = optional(object(<br>            {<br>              size = optional(number, 100)<br>              type = optional(string, "gp3")<br>            }),<br>            {<br>              size = 100<br>              type = "gp3"<br>            }<br>          )<br>      }),<br>      gpu = object(<br>        {<br>          ami            = optional(string)<br>          instance_type  = optional(string, "g4dn.xlarge")<br>          min_per_az     = optional(number, 0)<br>          max_per_az     = optional(number, 10)<br>          desired_per_az = optional(number, 0)<br>          labels = optional(map(string), {<br>            "dominodatalab.com/node-pool" = "default-gpu"<br>            "nvidia.com/gpu"              = true<br>          })<br>          volume = optional(object(<br>            {<br>              size = optional(number, 100)<br>              type = optional(string, "gp3")<br>            }),<br>            {<br>              size = 100<br>              type = "gp3"<br>            }<br>          )<br>      })<br>  })</pre> | <pre>{<br>  "compute": {},<br>  "gpu": {},<br>  "platform": {}<br>}</pre> | no |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID. | `string` | `"domino-eks"` | no |
| <a name="input_efs_access_point_path"></a> [efs\_access\_point\_path](#input\_efs\_access\_point\_path) | Filesystem path for efs. | `string` | `"/domino"` | no |
| <a name="input_eks_master_role_names"></a> [eks\_master\_role\_names](#input\_eks\_master\_role\_names) | IAM role names to be added as masters in eks. | `list(string)` | `[]` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | EKS cluster k8s version. | `string` | `"1.23"` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | fully qualified path name to write the kubeconfig file | `string` | `""` | no |
| <a name="input_number_of_azs"></a> [number\_of\_azs](#input\_number\_of\_azs) | Number of AZ to distribute the deployment, EKS needs at least 2. | `number` | `3` | no |
| <a name="input_private_cidr_network_bits"></a> [private\_cidr\_network\_bits](#input\_private\_cidr\_network\_bits) | Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs. | `number` | `19` | no |
| <a name="input_public_cidr_network_bits"></a> [public\_cidr\_network\_bits](#input\_public\_cidr\_network\_bits) | Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs. | `number` | `27` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Optional hosted zone for External DNSone. | `string` | `""` | no |
| <a name="input_s3_force_destroy_on_deletion"></a> [s3\_force\_destroy\_on\_deletion](#input\_s3\_force\_destroy\_on\_deletion) | Toogle to allow recursive deletion of all objects in the s3 buckets. if 'false' terraform will NOT be able to delete non-empty buckets | `bool` | `false` | no |
| <a name="input_ssh_pvt_key_path"></a> [ssh\_pvt\_key\_path](#input\_ssh\_pvt\_key\_path) | SSH private key filepath. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Deployment tags. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for bringing your own vpc, will bypass creation of such. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_ip"></a> [bastion\_ip](#output\_bastion\_ip) | public ip of the bastion |
| <a name="output_domino_key_pair"></a> [domino\_key\_pair](#output\_domino\_key\_pair) | Domino key pair |
| <a name="output_efs_access_point"></a> [efs\_access\_point](#output\_efs\_access\_point) | EFS access point |
| <a name="output_efs_file_system"></a> [efs\_file\_system](#output\_efs\_file\_system) | EFS file system |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | Domino instance URL. |
| <a name="output_k8s_tunnel_command"></a> [k8s\_tunnel\_command](#output\_k8s\_tunnel\_command) | Command to run the k8s tunnel mallory. |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | location of kubeconfig |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | S3 buckets |
| <a name="output_ssh_bastion_command"></a> [ssh\_bastion\_command](#output\_ssh\_bastion\_command) | Command to ssh into the bastion host |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
