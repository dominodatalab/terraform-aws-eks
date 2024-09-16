data "aws_iam_policy_document" "service_account_assume_role" {
  statement {
    sid     = "ServiceAccountAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(local.oidc_provider_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(local.oidc_provider_url, "https://")}:sub"
      values = [
        "system:serviceaccount:${var.namespace}:${var.operator_service_account_name}"
      ]
    }
  }
}
data "aws_iam_policy_document" "self_sagemaker_assume_role" {
  statement {
    sid     = "SelfAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"
      ]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.operator_role}"
      ]
    }
  }
  statement {
    sid     = "SagemakerAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "operator_assume_role_policy" {
  source_policy_documents = concat(
    [data.aws_iam_policy_document.service_account_assume_role.json],
    var.enable_in_account_deployments ? [data.aws_iam_policy_document.self_sagemaker_assume_role.json] : []
  )
}

resource "aws_iam_role" "operator" {
  name               = local.operator_role
  assume_role_policy = data.aws_iam_policy_document.operator_assume_role_policy.json
}
