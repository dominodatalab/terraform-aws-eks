data "aws_iam_policy_document" "trident_operator" {
  count = var.netapp_trident_operator.enabled ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.netapp_trident_operator.region}:${data.aws_caller_identity.aws_account.account_id}:secret:${local.name_prefix}-fsx-ontap-*"]

    actions = [
      "secretsmanager:GetSecretValue"
    ]
  }

  statement {
    effect = "Allow"

    resources = ["*"]

    actions = [
      "fsx:DescribeFileSystems",
      "fsx:DescribeVolumes",
      "fsx:CreateVolume",
      "fsx:RestoreVolumeFromSnapshot",
      "fsx:DescribeStorageVirtualMachines",
      "fsx:UntagResource",
      "fsx:UpdateVolume",
      "fsx:TagResource",
      "fsx:DeleteVolume"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:kms:${var.netapp_trident_operator.region}:${data.aws_caller_identity.aws_account.account_id}:key/${local.name_prefix}*"]
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
  }
}

resource "aws_iam_policy" "trident_operator" {
  count       = var.netapp_trident_operator.enabled ? 1 : 0
  name        = "${local.name_prefix}-fsx-policy"
  description = "Policy for FSx operations and Secrets Manager access"

  policy = data.aws_iam_policy_document.trident_operator[0].json
}

resource "aws_iam_role" "trident_operator" {
  count = var.netapp_trident_operator.enabled ? 1 : 0

  name = "${local.name_prefix}-trident-operator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition : {
          StringEquals : {
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.netapp_trident_operator.namespace}:${var.netapp_trident_operator.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "trident_operator" {
  count      = var.netapp_trident_operator.enabled ? 1 : 0
  role       = aws_iam_role.trident_operator[0].name
  policy_arn = aws_iam_policy.trident_operator[0].arn
}
