# nodes

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nodes"></a> [nodes](#module\_nodes) | ./../../../../modules/nodes | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_remote_state.eks](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.infra](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional EKS managed node groups definition. | <pre>map(object({<br>    ami                        = optional(string)<br>    bootstrap_extra_args       = optional(string)<br>    instance_types             = list(string)<br>    spot                       = optional(bool)<br>    min_per_az                 = number<br>    max_per_az                 = number<br>    max_unavailable_percentage = optional(number)<br>    max_unavailable            = optional(number)<br>    desired_per_az             = number<br>    availability_zone_ids      = list(string)<br>    labels                     = map(string)<br>    taints = optional(list(object({<br>      key    = string<br>      value  = optional(string)<br>      effect = string<br>    })))<br>    tags = optional(map(string), {})<br>    gpu  = optional(bool)<br>    volume = object({<br>      size = string<br>      type = string<br>    })<br>  }))</pre> | `null` | no |
| <a name="input_default_node_groups"></a> [default\_node\_groups](#input\_default\_node\_groups) | EKS managed node groups definition. | <pre>object(<br>    {<br>      compute = object(<br>        {<br>          ami                        = optional(string)<br>          bootstrap_extra_args       = optional(string)<br>          instance_types             = optional(list(string))<br>          spot                       = optional(bool)<br>          min_per_az                 = optional(number)<br>          max_per_az                 = optional(number)<br>          max_unavailable_percentage = optional(number)<br>          max_unavailable            = optional(number)<br>          desired_per_az             = optional(number)<br>          availability_zone_ids      = list(string)<br>          labels                     = optional(map(string))<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })))<br>          tags = optional(map(string))<br>          gpu  = optional(bool)<br>          volume = optional(object({<br>            size = optional(number)<br>            type = optional(string)<br>            })<br>          )<br>      }),<br>      platform = object(<br>        {<br>          ami                        = optional(string)<br>          bootstrap_extra_args       = optional(string)<br>          instance_types             = optional(list(string))<br>          spot                       = optional(bool)<br>          min_per_az                 = optional(number)<br>          max_per_az                 = optional(number)<br>          max_unavailable_percentage = optional(number)<br>          max_unavailable            = optional(number)<br>          desired_per_az             = optional(number)<br>          availability_zone_ids      = list(string)<br>          labels                     = optional(map(string))<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })))<br>          tags = optional(map(string))<br>          gpu  = optional(bool)<br>          volume = optional(object({<br>            size = optional(number)<br>            type = optional(string)<br>          }))<br>      }),<br>      gpu = object(<br>        {<br>          ami                        = optional(string)<br>          bootstrap_extra_args       = optional(string)<br>          instance_types             = optional(list(string))<br>          spot                       = optional(bool)<br>          min_per_az                 = optional(number)<br>          max_per_az                 = optional(number)<br>          max_unavailable_percentage = optional(number)<br>          max_unavailable            = optional(number)<br>          desired_per_az             = optional(number)<br>          availability_zone_ids      = list(string)<br>          labels                     = optional(map(string))<br>          taints = optional(list(object({<br>            key    = string<br>            value  = optional(string)<br>            effect = string<br>          })))<br>          tags = optional(map(string), {})<br>          gpu  = optional(bool, null)<br>          volume = optional(object({<br>            size = optional(number)<br>            type = optional(string)<br>          }))<br>      })<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Nodes details. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
