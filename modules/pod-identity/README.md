# Pod Identity

This module creates custom [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
roles: an IAM role and policy per config, plus the association binding that role to a
single Kubernetes ServiceAccount.

## Why this is separate from `irsa`

The two modules do the same job by different mechanisms, and pod identity is the one to
reach for in new code:

* **No OIDC provider is involved.** The trust policy names the `pods.eks.amazonaws.com`
  service rather than a cluster-specific OIDC issuer, so a role stays valid if the cluster
  is rebuilt. `irsa` cannot offer that, and its callers gate on `cluster.oidc != null`.
* **Session tags.** Pod identity stamps `kubernetes-namespace`, `kubernetes-service-account`,
  `eks-cluster-name` and the pod name/uid onto the session, so a resource policy can condition
  on `aws:PrincipalTag/kubernetes-service-account` and bind access to *that ServiceAccount*
  rather than merely to a role ARN.
* **No annotation on the ServiceAccount.** The association is the binding, so the chart does
  not need the role ARN plumbed into its values.

It requires the `eks-pod-identity-agent` addon, which this repo installs by default (see
`cluster_addons` in `modules/eks/variables.tf`). A deployment that overrides `cluster_addons`
and drops the agent will produce roles that no pod can assume.

## Scoping

The trust policy is scoped to the cluster — principal `pods.eks.amazonaws.com`, conditioned on
`aws:SourceAccount` and on the cluster ARN — mirroring the policy Karpenter already uses in
`modules/eks/karpenter-iam.tf`. Per-ServiceAccount scoping comes from the association, not from
the trust document, which is why one document serves every config.

## Usage

```hcl
module "pod_identity" {
  source   = "./modules/pod-identity"
  eks_info = module.eks.info
  region   = module.infra.region

  additional_pod_identity_configs = [{
    name                = "filetask-objectstore"
    namespace           = "domino-compute"
    serviceaccount_name = "domino-filetask-objectstore"
    policy              = data.aws_iam_policy_document.filetask_objectstore.json
  }]
}
```

Note that a non-root container reads its credentials from a projected token file, so a pod
using one of these roles needs a `securityContext.fsGroup` matching its runtime user;
without it the AWS SDK silently falls through to the next credential source.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_pod_identity_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_pod_identity_configs"></a> [additional\_pod\_identity\_configs](#input\_additional\_pod\_identity\_configs) | Input for additional EKS Pod Identity configurations | <pre>list(object({<br/>    name                = string<br/>    namespace           = string<br/>    serviceaccount_name = string<br/>    policy              = string #json<br/>  }))</pre> | `[]` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br/>      specs {<br/>        name       = Cluster name.<br/>        account\_id = AWS account id where the cluster resides.<br/>      }<br/>    } | <pre>object({<br/>    cluster = object({<br/>      specs = object({<br/>        name       = string<br/>        account_id = string<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region the cluster resides in. Used to build the cluster ARN the trust policy is scoped to. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_associations"></a> [associations](#output\_associations) | Pod identity associations, keyed by config name |
| <a name="output_roles"></a> [roles](#output\_roles) | Roles mapping info, keyed by config name |
<!-- END_TF_DOCS -->
