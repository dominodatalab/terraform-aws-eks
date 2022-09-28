data "aws_route53_zone" "hosted" {
  count        = var.route53_hosted_zone_name != "" ? 1 : 0
  name         = var.route53_hosted_zone_name
  private_zone = false
}

data "aws_iam_policy_document" "route53" {
  count = var.route53_hosted_zone_name != "" ? 1 : 0
  statement {

    effect    = "Allow"
    resources = ["*"]
    actions   = ["route53:ListHostedZones"]
  }

  statement {

    effect    = "Allow"
    resources = data.aws_route53_zone.hosted.*.arn

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
  }
}

resource "aws_iam_policy" "route53" {
  count  = var.route53_hosted_zone_name != "" ? 1 : 0
  name   = "${var.deploy_id}-Route53"
  path   = "/"
  policy = data.aws_iam_policy_document.route53[0].json
}

resource "aws_iam_role_policy_attachment" "route53" {
  for_each   = var.route53_hosted_zone_name != "" ? toset([for r in module.eks.eks_node_roles : r.name]) : []
  policy_arn = aws_iam_policy.route53[0].arn
  role       = each.value
}
