# network

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
| [aws_default_network_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_ipv4_cidr_block_association.pod_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_availability_zone.zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_network_acls.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_acls) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_eks_elb_tags"></a> [add\_eks\_elb\_tags](#input\_add\_eks\_elb\_tags) | Toggle k8s cluster tag on subnet | `bool` | `true` | no |
| <a name="input_availability_zone_ids"></a> [availability\_zone\_ids](#input\_availability\_zone\_ids) | List of availability zone IDs where the subnets will be created | `list(string)` | n/a | yes |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The IPv4 CIDR block for the VPC. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | `""` | no |
| <a name="input_flow_log_bucket_arn"></a> [flow\_log\_bucket\_arn](#input\_flow\_log\_bucket\_arn) | Bucket for vpc flow logging | `object({ arn = string })` | `null` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | The IPv4 CIDR block for the VPC. | `string` | `"100.64.0.0/16"` | no |
| <a name="input_pod_cidrs"></a> [pod\_cidrs](#input\_pod\_cidrs) | list of cidrs for the pod subnets | `list(string)` | n/a | yes |
| <a name="input_private_cidrs"></a> [private\_cidrs](#input\_private\_cidrs) | list of cidrs for the private subnets | `list(string)` | n/a | yes |
| <a name="input_public_cidrs"></a> [public\_cidrs](#input\_public\_cidrs) | list of cidrs for the public subnets | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_use_pod_cidr"></a> [use\_pod\_cidr](#input\_use\_pod\_cidr) | Use additional pod CIDR range (ie 100.64.0.0/16) for pod/service networking | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pod_subnets"></a> [pod\_subnets](#output\_pod\_subnets) | List of pod subnet ID and AZ |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of private subnet ID and AZ |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of public subnet ID and AZ |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC id. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
