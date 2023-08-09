# network

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

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
| [aws_lb.nlbs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.listeners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.target_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route53_record.service_endpoint_private_dns_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route_table.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.lb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.lb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_subnet.pod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_service.vpc_endpoint_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [aws_vpc_ipv4_cidr_block_association.pod_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_availability_zone.zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.lb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_network_acls.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_acls) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
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
| <a name="input_network"></a> [network](#input\_network) | vpc = {<br>      id = Existing vpc id, it will bypass creation by this module.<br>      subnets = {<br>        private = Existing private subnets.<br>        public  = Existing public subnets.<br>        pod     = Existing pod subnets.<br>      }), {})<br>    }), {})<br>    network\_bits = {<br>      public  = Number of network bits to allocate to the public subnet. i.e /27 -> 32 IPs.<br>      private = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>      pod     = Number of network bits to allocate to the private subnet. i.e /19 -> 8,192 IPs.<br>    }<br>    cidrs = {<br>      vpc     = The IPv4 CIDR block for the VPC.<br>      pod     = The IPv4 CIDR block for the Pod subnets.<br>    }<br>    vpc\_endpoint\_services = [{<br>      name      = Name of the VPC Enpoint Service.<br>      ports     = List of ports exposing the VPC Enpoint Service. i.e [8080, 8081]<br>      cert\_arn  = Certificate ARN used by the NLB associated for the given VPC Endpoint Service.<br>      private\_dns = Private DNS for the VPC Enpoint Service.<br>    }]<br>    use\_pod\_cidr = Use additional pod CIDR range (ie 100.64.0.0/16) for pod networking. | <pre>object({<br>    vpc = optional(object({<br>      id = optional(string)<br>      subnets = optional(object({<br>        private = optional(list(string))<br>        public  = optional(list(string))<br>        pod     = optional(list(string))<br>      }))<br>    }))<br>    network_bits = optional(object({<br>      public  = optional(number)<br>      private = optional(number)<br>      pod     = optional(number)<br>      }<br>    ))<br>    cidrs = optional(object({<br>      vpc = optional(string)<br>      pod = optional(string)<br>    }))<br>    vpc_endpoint_services = optional(list(object({<br>      name        = optional(string)<br>      ports       = optional(list(number))<br>      cert_arn    = optional(string)<br>      private_dns = optional(string)<br>    })))<br>    use_pod_cidr = optional(bool)<br>  })</pre> | n/a | yes |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | EKS managed node groups definition. | <pre>map(object({<br>    ami                   = string<br>    bootstrap_extra_args  = string<br>    instance_types        = list(string)<br>    spot                  = bool<br>    min_per_az            = number<br>    max_per_az            = number<br>    desired_per_az        = number<br>    availability_zone_ids = list(string)<br>    labels                = map(string)<br>    taints = list(object({<br>      key    = string<br>      value  = string<br>      effect = string<br>    }))<br>    tags          = map(string)<br>    instance_tags = map(string)<br>    gpu           = bool<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_name"></a> [route53\_hosted\_zone\_name](#input\_route53\_hosted\_zone\_name) | Hosted zone for External DNS zone. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Nework information. vpc\_id, subnets, target groups... |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
