locals {
  waf_name = "${var.deploy_id}-waf"
}

resource "aws_wafv2_web_acl" "waf" {
  # checkov:skip=CKV_AWS_192:WAF enables message lookup in Log4j2. Rules are configured at deployer level, anyway we are including "AWSManagedRulesKnownBadInputsRuleSet"
  # checkov:skip=CKV_AWS_342:WAF rule does not have any actions. Rules are dynamic
  count = var.waf.enabled ? 1 : 0

  name  = local.waf_name
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = toset(var.waf.rules)
    content {
      name     = "${rule.value.vendor_name}-${rule.value.name}"
      priority = rule.value.priority

      dynamic "override_action" {
        for_each = var.waf.override_action == "none" ? [1] : []
        content {
          none {}
        }
      }

      dynamic "override_action" {
        for_each = var.waf.override_action == "count" ? [1] : []
        content {
          count {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
          dynamic "managed_rule_group_configs" {
            for_each = rule.value.name == "AWSManagedRulesBotControlRuleSet" ? [1] : []
            content {
              aws_managed_rules_bot_control_rule_set {
                inspection_level        = "COMMON"
                enable_machine_learning = false
              }
            }
          }
          dynamic "rule_action_override" {
            for_each = rule.value.allow
            content {
              name = rule_action_override.value
              action_to_use {
                allow {}
              }
            }
          }
          dynamic "rule_action_override" {
            for_each = rule.value.block
            content {
              name = rule_action_override.value
              action_to_use {
                block {}
              }
            }
          }
          dynamic "rule_action_override" {
            for_each = rule.value.count
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }
            }
          }
          dynamic "rule_action_override" {
            for_each = rule.value.challenge
            content {
              name = rule_action_override.value
              action_to_use {
                challenge {}
              }
            }
          }
          dynamic "rule_action_override" {
            for_each = rule.value.captcha
            content {
              name = rule_action_override.value
              action_to_use {
                captcha {}
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.waf.rate_limit.enabled ? [1] : []
    content {
      name     = "GlobalRateLimit"
      priority = length(var.waf.rules) + 1

      dynamic "action" {
        for_each = var.waf.rate_limit.action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = var.waf.rate_limit.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      statement {
        rate_based_statement {
          limit              = var.waf.rate_limit.limit
          aggregate_key_type = "IP"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GlobalRateLimit"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.waf.block_forwarder_header.enabled ? [1] : []

    content {
      name     = "BlockXForwardedFor"
      priority = length(var.waf.rules) + (var.waf.rate_limit.enabled ? 2 : 1)

      action {
        block {}
      }

      statement {
        byte_match_statement {
          search_string = "."
          field_to_match {
            single_header {
              name = "x-forwarded-for"
            }
          }
          text_transformation {
            priority = 0
            type     = "NONE"
          }
          positional_constraint = "CONTAINS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BlockXForwardedFor"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cw-${local.waf_name}"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_association" {
  for_each = local.albs

  resource_arn = aws_lb.load_balancers[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.waf[0].arn
}

resource "aws_s3_bucket" "waf_logs" {
  count = var.waf.enabled ? 1 : 0

  bucket        = "aws-waf-logs-${var.deploy_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  count = var.waf.enabled ? 1 : 0

  bucket                  = aws_s3_bucket.waf_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.deploy_id}-blocked" #Note: The Log group must start with aws-waf-logs-
  retention_in_days = 14
}

resource "aws_cloudwatch_log_resource_policy" "waf_log_group_policy" {
  policy_document = data.aws_iam_policy_document.waf_log_group_policy_document.json
  policy_name     = "${var.deploy_id}-waf_log_group_policy"
}

resource "aws_wafv2_web_acl_logging_configuration" "application" {
  count = var.waf.enabled ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.waf[0].arn

  # Only keep blocked requests to save storage and Insight query costs
  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior    = "KEEP"
      requirement = "MEETS_ANY"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }

      condition {
        action_condition {
          action = "COUNT"
        }
      }
    }
  }
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "waf_log_group_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.waf_logs.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}
