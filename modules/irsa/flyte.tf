resource "aws_iam_role" "create_flyte_role" {
  # TODO: Conditional on flyte enabled
  name = "${local.name_prefix}-flyte-controlplane-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
          # "arn:aws:iam::${local.aws_account_id}:oidc-provider/${var.eks.identity_providers.issuer_url}"
        }
        Condition : {
          StringEquals : {
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : [
              "system:serviceaccount:flyte:flyteadmin",
              "system:serviceaccount:flyte:datacatalog"
            ]
          }
        }
      },
    ]
  })
}