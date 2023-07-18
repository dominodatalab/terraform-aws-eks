locals {
  endpoint_services = tomap({for service in var.network.vpc_endpoint_services : "${service.name}" => service.private_dns})

  listeners = distinct(flatten([
    for service in var.network.vpc_endpoint_services : [
      for port in service.ports : {
        service  = service.name
        port     = port
        cert_arn = service.cert_arn
      }
    ]
  ]))
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.deploy_id}-lb-logs"

  force_destroy = true
  object_lock_enabled = false
}

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = data.aws_iam_policy_document.lb_logs.json
}

data "aws_iam_policy_document" "lb_logs" {
  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.deploy_id}-lb-logs"]
    actions   = ["s3:GetBucketAcl"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${local.aws_account_id}"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.region}:${local.aws_account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.deploy_id}-lb-logs/AWSLogs/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${local.aws_account_id}"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.region}:${local.aws_account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}


resource "aws_lb" "nlbs" {
  for_each = local.endpoint_services

  name               = "${var.deploy_id}-${each.key}"
  load_balancer_type = "network"

  subnets = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    enabled = true
  }
}

resource "aws_lb_target_group" "target_groups" {
  for_each = local.endpoint_services

  name     = "${var.deploy_id}-${each.key}"
  port     = 80 # Not used but required
  protocol = "TCP"
  vpc_id   = aws_vpc.this[0].id
}

resource "aws_lb_listener" "listeners" {
  for_each = { for entry in local.listeners : "${entry.service}.${entry.port}" => entry }

  load_balancer_arn = aws_lb.nlbs[each.value.service].arn
  port              = each.value.port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = each.value.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.value.service].arn
  }
}

resource "aws_vpc_endpoint_service" "vpc_endpoint_services" {
  for_each = local.endpoint_services

  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlbs[each.key].arn]

  private_dns_name = each.value

}