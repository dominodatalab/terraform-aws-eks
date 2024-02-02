# irsa-flyte

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
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
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.flyte_controlplane_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.flyte_dataplane_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.aws_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      specs {<br>        name            = Cluster name.<br>      }<br>      oidc = {<br>        arn = OIDC provider ARN.<br>        url = OIDC provider url.<br>        cert = {<br>          thumbprint\_list = OIDC cert thumbprints.<br>          url             = OIDC cert URL.<br>      }<br>    } | <pre>object({<br>    cluster = object({<br>      specs = object({<br>        name = string<br>      })<br>      oidc = object({<br>        arn = string<br>        url = string<br>        cert = object({<br>          thumbprint_list = list(string)<br>          url             = string<br>        })<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_flyte"></a> [flyte](#input\_flyte) | enabled = Whether to provision any Flyte related resources<br>    eks = {<br>      controlplane\_role = Name of control plane role to create for Flyte<br>      dataplane\_role = Name of data plane role to create for Flyte<br>    } | <pre>object({<br>    enabled = optional(bool, false)<br>    eks = optional(object({<br>      controlplane_role = optional(string, "flyte-controlplane-role")<br>      dataplane_role    = optional(string, "flyte-dataplane-role")<br>    }))<br>  })</pre> | `{}` | no |
| <a name="input_use_cluster_odc_idp"></a> [use\_cluster\_odc\_idp](#input\_use\_cluster\_odc\_idp) | Toogle to uset the oidc idp connector in the trust policy.<br>    Set to `true` if the cluster and the hosted zone are in different aws accounts. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_flyte"></a> [flyte](#output\_flyte) | Flyte info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
