locals {
  aws_account_id = data.aws_caller_identity.aws_account.account_id
}

data "aws_iam_policy_document" "kms_key_global" {
  count = local.create_kms_key

  override_policy_documents = var.kms.additional_policies

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
      "kms:Encrypt",
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

locals {
  create_kms_key = var.kms.key_id == null ? 1 : 0
  provided_key   = var.kms.key_id != null ? 1 : 0
}

resource "aws_kms_key" "domino" {
  count                    = local.create_kms_key
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
  count         = local.create_kms_key
  name          = "alias/${var.deploy_id}"
  target_key_id = aws_kms_key.domino[0].key_id
}

data "aws_kms_key" "key" {
  count  = local.provided_key
  key_id = var.kms.key_id
}
