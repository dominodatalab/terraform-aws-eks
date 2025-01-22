# single_node
:x: **DO NOT USE TO PROVISION INFRASTRUCTURE.This implementation is meant for internal purposes ONLY.** :anger:

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_single_node"></a> [single\_node](#module\_single\_node) | ./../../../modules/single-node | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_remote_state.eks](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.infra](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ignore_tags"></a> [ignore\_tags](#input\_ignore\_tags) | Tag keys to be ignored by the aws provider. | `list(string)` | `[]` | no |
| <a name="input_single_node"></a> [single\_node](#input\_single\_node) | Additional EKS managed node groups definition. | <pre>object({<br/>    name                 = optional(string, "single-node")<br/>    bootstrap_extra_args = optional(string, "")<br/>    ami = optional(object({<br/>      name_prefix = optional(string, null)<br/>      owner       = optional(string, null)<br/><br/>    }))<br/>    instance_type            = optional(string, "m6i.2xlarge")<br/>    authorized_ssh_ip_ranges = optional(list(string), ["0.0.0.0/0"])<br/>    labels                   = optional(map(string))<br/>    taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string)<br/>      effect = string<br/>    })), [])<br/>    volume = optional(object({<br/>      size = optional(number, 1000)<br/>      type = optional(string, "gp3")<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_info"></a> [info](#output\_info) | Single Node details. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
