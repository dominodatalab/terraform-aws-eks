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
    name                = "my-workload"
    namespace           = "domino-compute"
    serviceaccount_name = "my-workload"
    policy              = data.aws_iam_policy_document.my_workload.json
  }]
}
```

### S3 Files dataset storage

That feature has its own input rather than a hand-written config, because the policy it needs is
per-bucket and Domino publishes it to customers. `filetask-objectstore.tf` builds it; see
`modules/eks` for the separate mount grant it needs on the node role.

```hcl
module "pod_identity" {
  source   = "./modules/pod-identity"
  eks_info = module.eks.info
  region   = module.infra.region

  filetask_objectstore = {
    enabled = true
    buckets = [{
      name        = "my-dataset-bucket"
      prefix      = "datasets"          # omit for a whole-bucket file system
      kms_key_arn = null                # required only for an SSE-KMS bucket
    }]
  }
}

module "eks" {
  # ...
  filetask_objectstore_mount_enabled = true
}
```

The buckets must already exist — nothing here creates a bucket, a file system, or a mount target.
The list only scopes IAM.

**Migrating from a hand-written config.** This example used to configure exactly this feature through
`additional_pod_identity_configs`. Setting both now fails at plan: the IAM role and policy names
collide and EKS permits only one association per namespace/ServiceAccount pair. Delete the manual
entry when you set `filetask_objectstore`.

## Validation

Three input rules reject at plan time. None of them appear in the generated table below,
because terraform-docs does not render `validation` blocks:

* `policy` must parse as JSON.
* `region` must be region-shaped, e.g. `eu-west-1`.
* A `namespace`/`serviceaccount_name` pair may appear only once. EKS permits one pod identity
  association per pair, so a duplicate would otherwise get through plan and fail at apply.
* `filetask_objectstore` bucket names, prefixes and KMS key ARNs are checked: a prefix must be
  literal, because a `*` there spans `/` and would widen the grant to sibling paths, and a key ARN
  must be a full regional one, because a bare id or an alias builds a policy that reads as
  configured and denies every operation.
* With `filetask_objectstore` enabled, no `additional_pod_identity_configs` entry may duplicate it —
  by name or by namespace/ServiceAccount. That one is a resource precondition rather than a variable
  validation, since a validation cannot see a second variable.

`bin/pre-commit/validate-filetask-policies.py` renders the S3 Files policies and compares them to
`bin/pre-commit/filetask-expected-policies.json`, so a change to what Domino grants cannot land
without updating the fixture — and, with it, the customer-facing IAM page.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
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
| [aws_eks_pod_identity_association.filetask_objectstore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_eks_pod_identity_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_policy.filetask_objectstore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.filetask_objectstore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.filetask_objectstore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.filetask_objectstore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_pod_identity_configs"></a> [additional\_pod\_identity\_configs](#input\_additional\_pod\_identity\_configs) | Input for additional EKS Pod Identity configurations | <pre>list(object({<br/>    name                = string<br/>    namespace           = string<br/>    serviceaccount_name = string<br/>    policy              = string #json<br/>  }))</pre> | `[]` | no |
| <a name="input_eks_info"></a> [eks\_info](#input\_eks\_info) | cluster = {<br/>      specs {<br/>        name       = Cluster name.<br/>        account\_id = AWS account id where the cluster resides.<br/>      }<br/>    } | <pre>object({<br/>    cluster = object({<br/>      specs = object({<br/>        name       = string<br/>        account_id = string<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_filetask_objectstore"></a> [filetask\_objectstore](#input\_filetask\_objectstore) | S3 Files dataset storage for Domino's s3-native dataset tasks.<br/><br/>    `buckets` declares buckets that already exist and is used only to scope IAM -- nothing here<br/>    creates a bucket, a file system, or a mount target. Each entry is:<br/>      name        = bucket backing an S3 File System.<br/>      prefix      = key prefix the file system is scoped to, omitted for a whole-bucket one.<br/>      kms\_key\_arn = required only for an SSE-KMS bucket; must be a regional key ARN.<br/><br/>    The ServiceAccount name is part of the supported interface: the association is keyed on it,<br/>    and so is the Domino chart that creates the account. Changing it breaks every bound role. | <pre>object({<br/>    enabled             = optional(bool, false)<br/>    namespace           = optional(string, "domino-compute")<br/>    serviceaccount_name = optional(string, "domino-filetask-objectstore")<br/>    buckets = optional(list(object({<br/>      name        = string<br/>      prefix      = optional(string)<br/>      kms_key_arn = optional(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region the cluster resides in. Used to build the cluster ARN the trust policy is scoped to. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_associations"></a> [associations](#output\_associations) | Pod identity associations, keyed by config name |
| <a name="output_filetask_objectstore_role_arn"></a> [filetask\_objectstore\_role\_arn](#output\_filetask\_objectstore\_role\_arn) | ARN of the S3 Files task role, or null when filetask\_objectstore is not enabled |
| <a name="output_roles"></a> [roles](#output\_roles) | Roles mapping info, keyed by config name |
<!-- END_TF_DOCS -->
