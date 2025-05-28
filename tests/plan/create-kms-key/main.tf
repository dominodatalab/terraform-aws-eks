data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

locals {
  aws_account_id = data.aws_caller_identity.aws_account.account_id
}

data "aws_iam_policy_document" "kms_key_global" {
  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:GenerateDataKey*",
      "kms:TagResource",
      "kms:UntagResource"
    ]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:root",
        "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
    }
  }

  statement {
    actions = [
      "kms:CreateGrant"
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
    resources = ["*"]
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
  }
}

resource "aws_kms_key" "custom" {
  description              = "Custom KMS key to secure data for Domino"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = false
  policy                   = data.aws_iam_policy_document.kms_key_global.json
  deletion_window_in_days  = 7
  tags = {
    "Name" = var.deploy_id
  }
}

resource "aws_kms_alias" "custom" {
  name          = "alias/${var.deploy_id}-custom"
  target_key_id = aws_kms_key.custom.key_id
}
