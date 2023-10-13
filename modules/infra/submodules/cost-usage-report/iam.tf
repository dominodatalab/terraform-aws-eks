# three IAM roles

data "aws_iam_policy_document" "cur_crawler_component_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "aws_cur_crawler_component_function_role" {
  name_prefix        = "crawler_component_function_role"
  assume_role_policy = data.aws_iam_policy_document.cur_crawler_component_assume_role_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "aws_cur_crawler_component_function_policy" {

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }

  statement {
    sid = "Glue"

    effect = "Allow"

    actions = [
      "glue:ImportCatalogToGlue",
      "glue:GetDatabase",
      "glue:UpdateDatabase",
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:BatchGetPartition",
      "glue:UpdatePartition",
      "glue:BatchCreatePartition",
      "glue:GetSecurityConfiguration",
    ]

    resources = ["*"]
  }

  statement {
    sid = "S3"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutBucket",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}/${var.s3_bucket_prefix}/dominoCost/dominoCost*",
    ]
  }

  statement {
    sid = "S3Decrypt"

    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = [
      local.kms_key_arn
    ]
  }

}

resource "aws_iam_role_policy" "aws_cur_crawler_component_function_policy" {
  role   = aws_iam_role.aws_cur_crawler_component_function_role.name
  policy = data.aws_iam_policy_document.aws_cur_crawler_component_function_policy.json
}


data "aws_iam_policy_document" "aws_cur_crawler_lambda_executor_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "aws_cur_crawler_lambda_executor" {
  name               = "${var.cur_report_name}-crawler-lambda-executor"
  assume_role_policy = data.aws_iam_policy_document.aws_cur_crawler_lambda_executor_assume.json
}

data "aws_iam_policy_document" "aws_cur_crawler_lambda_executor" {

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }

  statement {
    sid = "Glue"

    effect = "Allow"

    actions = [
      "glue:StartCrawler",
    ]

    resources = [aws_glue_crawler.aws_cur_crawler.arn]
  }
}

resource "aws_iam_role_policy" "aws_cur_crawler_lambda_executor" {
  role   = aws_iam_role.aws_cur_crawler_lambda_executor.name
  policy = data.aws_iam_policy_document.aws_cur_crawler_lambda_executor.json
}


data "aws_iam_policy_document" "aws_cur_lambda_executor_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "aws_cur_lambda_executor" {
  name               = "${var.cur_report_name}-lambda-executor"
  assume_role_policy = data.aws_iam_policy_document.aws_cur_lambda_executor_assume.json
}

data "aws_iam_policy_document" "aws_cur_lambda_executor" {

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }

  statement {
    sid = "Glue"

    effect = "Allow"

    actions = [
      "s3:PutBucketNotification"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}"
    ]
  }
}

resource "aws_iam_role_policy" "aws_cur_lambda_executor" {
  role   = aws_iam_role.aws_cur_lambda_executor.name
  policy = data.aws_iam_policy_document.aws_cur_lambda_executor.json
}

