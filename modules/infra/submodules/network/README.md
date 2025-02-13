# network

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.7 |

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
| [aws_security_group.ecr_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.ecr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_dkr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_ipv4_cidr_block_association.pod_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_availability_zone.zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_network_acls.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_acls) | data source |
| [aws_prefix_list.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/prefix_list) | data source |
| [aws_subnet.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.provided](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_eks_elb_tags"></a> [add\_eks\_elb\_tags](#input\_add\_eks\_elb\_tags) | Toggle k8s cluster tag on subnet | `bool` | `true` | no |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | Domino Deployment ID | `string` | n/a | yes |
| <a name="input_flow_log_bucket_arn"></a> [flow\_log\_bucket\_arn](#input\_flow\_log\_bucket\_arn) | Bucket for vpc flow logging | `object({ arn = string })` | `null` | no |
| <a name="input_network"></a> [network](#input\_network) | vpc = {<br/>      id = Existing vpc id, it will bypass creation by this module.<br/>      subnets = {<br/>        private = Existing private subnets.<br/>        public  = Existing public subnets.<br/>        pod     = Existing pod subnets.<br/>      }), {})<br/>    }), {})<br/>    network\_bits = {<br/>      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.<br/>      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br/>      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br/>    }<br/>    cidrs = {<br/>      vpc     = The IPv4 CIDR block for the VPC.<br/>      pod     = The IPv4 CIDR block for the Pod subnets.<br/>    }<br/>    use\_pod\_cidr        = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking.<br/>    create\_ecr\_endpoint = Create the VPC Endpoint For ECR. | <pre>object({<br/>    vpc = optional(object({<br/>      id = optional(string)<br/>      subnets = optional(object({<br/>        private = optional(list(string))<br/>        public  = optional(list(string))<br/>        pod     = optional(list(string))<br/>      }))<br/>    }))<br/>    network_bits = optional(object({<br/>      public  = optional(number)<br/>      private = optional(number)<br/>      pod     = optional(number)<br/>      }<br/>    ))<br/>    cidrs = optional(object({<br/>      vpc = optional(string)<br/>      pod = optional(string)<br/>    }))<br/>    use_pod_cidr        = optional(bool)<br/>    create_ecr_endpoint = optional(bool, false)<br/>  })</pre> | n/a | yes |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | EKS managed node groups definition. | <pre>map(object({<br/>    ami                   = string<br/>    bootstrap_extra_args  = string<br/>    instance_types        = list(string)<br/>    spot                  = bool<br/>    min_per_az            = number<br/>    max_per_az            = number<br/>    desired_per_az        = number<br/>    availability_zone_ids = list(string)<br/>    labels                = map(string)<br/>    taints = list(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    }))<br/>    tags          = map(string)<br/>    instance_tags = map(string)<br/>    gpu           = bool<br/>    volume = object({<br/>      size       = string<br/>      type       = string<br/>      iops       = optional(number)<br/>      throughput = optional(number, 500)<br/>    })<br/>  }))</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Nework information. vpc\_id, subnets... |
<!-- END_TF_DOCS -->
