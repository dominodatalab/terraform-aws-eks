# IRSA

This module is an opinionated implementation of predefined and custom `irsa` roles for EKS.

## Predefined IRSA roles

* `external-dns`

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
| [aws_iam_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.hosted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_irsa_configs"></a> [additional\_irsa\_configs](#input\_additional\_irsa\_configs) | Input for additional irsa configurations | <pre>list(object({<br>    name                = string<br>    namespace           = string<br>    serviceaccount_name = string<br>    policy              = string #json<br>  }))</pre> | `[]` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br>      specs {<br>        name            = Cluster name.<br>      }<br>      oidc = {<br>        arn = OIDC provider ARN.<br>        url = OIDC provider url.<br>        cert = {<br>          thumbprint\_list = OIDC cert thumbprints.<br>          url             = OIDC cert URL.<br>      }<br>    } | <pre>object({<br>    cluster = object({<br>      specs = object({<br>        name = string<br>      })<br>      oidc = object({<br>        arn = string<br>        url = string<br>        cert = object({<br>          thumbprint_list = list(string)<br>          url             = string<br>        })<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Config to enable irsa for external-dns | <pre>object({<br>    enabled             = optional(bool, false)<br>    hosted_zone_name    = optional(string, null)<br>    hosted_zone_private = optional(string, false)<br>    namespace           = optional(string, "domino-platform")<br>    serviceaccount_name = optional(string, "external-dns")<br>  })</pre> | `{}` | no |
| <a name="input_use_cluster_odc_idp"></a> [use\_cluster\_odc\_idp](#input\_use\_cluster\_odc\_idp) | Toogle to uset the oidc idp connector in the trust policy.<br>    Set to `true` if the cluster and the hosted zone are in different aws accounts. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_dns"></a> [external\_dns](#output\_external\_dns) | External\_dns info |
| <a name="output_roles"></a> [roles](#output\_roles) | Roles mapping info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
