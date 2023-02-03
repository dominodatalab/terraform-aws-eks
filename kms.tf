data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

locals {
  aws_account_id = data.aws_caller_identity.aws_account.account_id
}

data "aws_iam_policy_document" "kms_key_global" {
  count = var.use_kms && var.kms_key_id == null ? 1 : 0
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

resource "aws_kms_key" "domino" {
  count                    = var.use_kms && var.kms_key_id == null ? 1 : 0
  description              = "KMS key to secure data for Domino"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = false
  policy                   = data.aws_iam_policy_document.kms_key_global[0].json
  tags = {
    "Name" = var.deploy_id
  }
}

resource "aws_kms_alias" "domino" {
  count         = var.use_kms && var.kms_key_id == null ? 1 : 0
  name          = "alias/${var.deploy_id}"
  target_key_id = aws_kms_key.domino[0].key_id
}

data "aws_kms_key" "key" {
  count  = var.use_kms && var.kms_key_id != null ? 1 : 0
  key_id = var.kms_key_id
}
