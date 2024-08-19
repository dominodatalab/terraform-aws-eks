resource "aws_iam_role" "external_deployments_operator" {
  count = var.external_deployments_operator.enabled ? 1 : 0

  name = "${local.name_prefix}-external-deployments-operator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition : {
          StringEquals : {
            StringEquals : {
              "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.external_deployments_operator.namespace}:${var.external_deployments_operator.serviceaccount_name}"
            }
          }
        }
      },
    ]
  })
}
