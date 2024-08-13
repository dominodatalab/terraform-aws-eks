resource "aws_iam_role" "model_deployment_operator" {
  name = "${local.deploy_id}-model-deployment-operator"
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
              "system:serviceaccount:${var.compute_namespace}:${var.serviceaccount_names.operator}",
            ]
          }
        }
      },
    ]
  })
}
