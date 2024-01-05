#External DNS IRSA configuration
data "aws_route53_zone" "hosted" {
  count = var.external_dns.enabled ? 1 : 0
  name  = var.external_dns.hosted_zone_name
}

data "aws_iam_policy_document" "external_dns" {
  count = var.external_dns.enabled ? 1 : 0
  statement {

    effect    = "Allow"
    resources = ["*"]
    actions   = ["route53:ListHostedZones"]
  }

  statement {

    effect    = "Allow"
    resources = data.aws_route53_zone.hosted[*].arn

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
  }
}

resource "aws_iam_role" "external_dns" {
  count = var.external_dns.enabled ? 1 : 0
  name  = "${local.name_prefix}-external-dns"
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
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com"
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.external_dns.namespace}:${var.external_dns.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "external_dns" {
  count  = var.external_dns.enabled ? 1 : 0
  name   = "${local.name_prefix}-external-dns"
  path   = "/"
  policy = data.aws_iam_policy_document.external_dns[0].json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count      = var.external_dns.enabled ? 1 : 0
  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.external_dns[0].arn
}
