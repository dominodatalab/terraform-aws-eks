data "aws_iam_policy_document" "trident_configurator" {
  count = var.netapp_trident_configurator.enabled ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.netapp_trident_configurator.region}:${data.aws_caller_identity.aws_account.account_id}:secret:${local.name_prefix}-netapp-ontap-*"]

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
  }
}

resource "aws_iam_policy" "trident_configurator" {
  count       = var.netapp_trident_configurator.enabled ? 1 : 0
  name        = "${local.name_prefix}-trident-configurator-policy"
  description = "Policy for NetApp operations and Secrets Manager access"

  policy = data.aws_iam_policy_document.trident_configurator[0].json
}

resource "aws_iam_role" "trident_configurator" {
  count = var.netapp_trident_configurator.enabled ? 1 : 0

  name = "${local.name_prefix}-trident-configurator"
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
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.netapp_trident_configurator.namespace}:${var.netapp_trident_configurator.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "trident_configurator" {
  count      = var.netapp_trident_configurator.enabled ? 1 : 0
  role       = aws_iam_role.trident_configurator[0].name
  policy_arn = aws_iam_policy.trident_configurator[0].arn
}
