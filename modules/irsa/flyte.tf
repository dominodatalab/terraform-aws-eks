resource "aws_iam_role" "flyte_controlplane_role" {
  count = var.flyte.enabled ? 1 : 0
  name  = "${local.name_prefix}-flyte-controlplane-role"
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

resource "aws_iam_role" "flyte_dataplane_role" {
  count = var.flyte.enabled ? 1 : 0
  name  = "${local.name_prefix}-flyte-dataplane-role"
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
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : [
              "system:serviceaccount:flyte:flytepropeller",
              "system:serviceaccount:*:default"
            ]
          }
        }
      },
    ]
  })
}