## EKS Pod Identity roles for platform service accounts. These replace the permissions platform
## pods previously inherited from the eks-nodes instance role, so they can run on platform nodes
## that use the minimal role (see separate_platform_node_role).
data "aws_iam_policy_document" "platform_pod_identity_trust" {
  statement {
    sid     = "PlatformPodIdentityAssumer"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_eks_cluster.this.arn]
    }
  }
}

data "aws_iam_policy_document" "platform_pod_identity_ebs_csi" {
  source_policy_documents = [
    data.aws_iam_policy_document.ebs_csi.json,
    data.aws_iam_policy_document.snapshot.json,
  ]
}

locals {
  platform_pod_identity_enabled = var.eks.platform_pod_identity.enabled

  platform_pod_identity_builtin = {
    cluster-autoscaler = {
      namespace       = "kube-system"
      service_account = "cluster-autoscaler"
      policy_json     = data.aws_iam_policy_document.autoscaler.json
      policy_arns     = []
    }
    ebs-csi = {
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      policy_json     = data.aws_iam_policy_document.platform_pod_identity_ebs_csi.json
      policy_arns     = []
    }
  }

  platform_pod_identity_roles = local.platform_pod_identity_enabled ? merge(
    local.platform_pod_identity_builtin,
    {
      for k, v in var.eks.platform_pod_identity.extra_roles : k => {
        namespace       = v.namespace
        service_account = v.service_account
        policy_json     = null
        policy_arns     = v.policy_arns
      }
    }
  ) : {}
}

resource "aws_iam_role" "platform_pod_identity" {
  for_each             = local.platform_pod_identity_roles
  name                 = "${var.deploy_id}-${each.key}-pod-identity"
  assume_role_policy   = data.aws_iam_policy_document.platform_pod_identity_trust.json
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_policy" "platform_pod_identity" {
  for_each = { for k, v in local.platform_pod_identity_roles : k => v if v.policy_json != null }
  name     = "${var.deploy_id}-${each.key}-pod-identity"
  path     = "/"
  policy   = each.value.policy_json
}

resource "aws_iam_role_policy_attachment" "platform_pod_identity_inline" {
  for_each   = aws_iam_policy.platform_pod_identity
  role       = aws_iam_role.platform_pod_identity[each.key].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "platform_pod_identity_managed" {
  for_each = merge([
    for k, v in local.platform_pod_identity_roles : {
      for arn in v.policy_arns : "${k}|${arn}" => { role = k, arn = arn }
    }
  ]...)
  role       = aws_iam_role.platform_pod_identity[each.value.role].name
  policy_arn = each.value.arn
}

resource "aws_eks_pod_identity_association" "platform" {
  for_each        = local.platform_pod_identity_roles
  cluster_name    = aws_eks_cluster.this.name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.platform_pod_identity[each.key].arn
}
