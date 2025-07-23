#External DNS IRSA configuration
data "aws_route53_zone" "hosted" {
  provider     = aws.global
  count        = var.external_dns.enabled ? 1 : 0
  name         = var.external_dns.hosted_zone_name
  private_zone = var.external_dns.hosted_zone_private
}

data "aws_iam_policy_document" "external_dns" {
  provider = aws.global
  count    = var.external_dns.enabled ? 1 : 0
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
  provider = aws.global
  count    = var.external_dns.enabled ? 1 : 0
  name     = "${local.name_prefix}-external-dns"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.external_dns_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition : {
          StringEquals : {
            "${trimprefix(local.external_dns_oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com"
            "${trimprefix(local.external_dns_oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.external_dns.namespace}:${var.external_dns.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "external_dns" {
  provider = aws.global
  count    = var.external_dns.enabled ? 1 : 0
  name     = "${local.name_prefix}-external-dns"
  path     = "/"
  policy   = data.aws_iam_policy_document.external_dns[0].json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  provider   = aws.global
  count      = var.external_dns.enabled ? 1 : 0
  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.external_dns[0].arn
}

resource "aws_iam_role_policy_attachment" "external_dns_extra_role" {
  provider   = aws.global
  count      = (var.external_dns.enabled && var.external_dns.extra_role) ? 1 : 0
  role       = var.external_dns.extra_role
  policy_arn = aws_iam_policy.external_dns[0].arn
}

## Delete pre-existing route53 policy attached to nodes.
resource "terraform_data" "delete_route53_policy" {
  count = var.external_dns.enabled && var.external_dns.rm_role_policy.remove ? 1 : 0

  triggers_replace = [
    var.external_dns.rm_role_policy.policy_name
  ]
  provisioner "local-exec" {
    command = <<-EOF
      set -x -o pipefail

      policy_arn="arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.aws_account.account_id}:policy/${var.external_dns.rm_role_policy.policy_name}"

      if aws iam get-policy --policy-arn "$policy_arn" &>/dev/null; then

        if [[ "${tostring(var.external_dns.rm_role_policy.detach_from_role)}" == "true" ]]; then
          for role in $(aws iam list-entities-for-policy --policy-arn "$policy_arn" --query 'PolicyRoles[*].RoleName' --output text || exit 1); do
              printf "Detaching IAM policy: $policy_arn from role: $role.\n"
              aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" || exit 1
          done
        fi

        printf "Deleting IAM policy: $policy_arn.\n"
        aws iam delete-policy --policy-arn "$policy_arn"

      else
        printf "IAM policy $policy_arn does not exist. Nothing to do.\n"
      fi

    EOF
    environment = {
      AWS_USE_FIPS_ENDPOINT = tostring(var.use_fips_endpoint)
    }
    interpreter = ["bash", "-c"]
  }
  depends_on = [aws_iam_role_policy_attachment.external_dns]
}
