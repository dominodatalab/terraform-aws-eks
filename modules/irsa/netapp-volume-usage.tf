resource "aws_iam_policy" "netapp_volume_usage" {
  count       = var.netapp_volume_usage.enabled ? 1 : 0
  name        = "${local.name_prefix}-netapp-volume-usage-policy"
  description = "Read the ONTAP SVM credentials secret for NetApp volume usage"

  # Exact secret ARNs, not the "<deploy_id>-netapp-ontap-*" wildcard the Trident roles use: that
  # wildcard also matches the fsxadmin filesystem secret, which this role must never read.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.netapp_volume_usage.secret_arns
      }
    ]
  })
}

resource "aws_iam_role" "netapp_volume_usage" {
  count = var.netapp_volume_usage.enabled ? 1 : 0

  name = "${local.name_prefix}-netapp-volume-usage"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" = "system:serviceaccount:${var.netapp_volume_usage.namespace}:${var.netapp_volume_usage.serviceaccount_name}"
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "netapp_volume_usage" {
  count      = var.netapp_volume_usage.enabled ? 1 : 0
  role       = aws_iam_role.netapp_volume_usage[0].name
  policy_arn = aws_iam_policy.netapp_volume_usage[0].arn
}
