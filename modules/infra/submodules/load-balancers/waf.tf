locals {
  waf_name = "domino-cloud"
}

resource "aws_wafv2_web_acl" "waf" {
  count = var.waf.enabled ? 1 : 0

  name  = "${local.waf_name}-waf"
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
      action {
        count {}
      }
      dynamic "action" {
        for_each = var.waf.rate_limit.action == "allow" ? [1] : []
        content {
          none {}
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
    metric_name                = "cw-${local.waf_name}-waf-alb"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_association" {
  for_each = local.albs

  resource_arn = aws_lb.load_balancers[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.waf[0].arn
}