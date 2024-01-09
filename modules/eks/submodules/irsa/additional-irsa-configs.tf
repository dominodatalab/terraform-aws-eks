resource "aws_iam_role" "this" {
  for_each = { for irsa in var.additional_irsa_configs : irsa.name => irsa }

  name = "${local.name_prefix}-${each.value.name}"
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
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${each.value.namespace}:${each.value.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  for_each = { for irsa in var.additional_irsa_configs : irsa.name => irsa }
  name     = "${local.name_prefix}-${each.value.name}"
  path     = "/"
  policy   = each.value.policy
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = { for irsa in var.additional_irsa_configs : irsa.name => irsa }
  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.this[each.key].arn
}
